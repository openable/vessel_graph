function vessel_graph
    % data
    showVertices = true;   % flag to determine whether to show node labels

    prevIdx = [];         % keeps track of 1st node clicked in creating edges
    selectIdx = [];       % used to highlight node selected in listbox

    pts = zeros(0,2);     % x/y coordinates of vertices
    adj = sparse([]);     % sparse adjacency matrix (undirected)    % ���� ���� ���� ���
    label = cell(0,4);      % ���� ���̺� ����� ����, ù��° �� / �ι�° �� / ���̺� �̸� / ���̺� ���� ����

    prevIdxV = [];
    selectIdxV = [];
    
    ptsV = zeros(0,2);     % x/y coordinates of vertices
    adjV = sparse([]);     % sparse adjacency matrix (undirected)    % ���� ���� ���� ���
    labelV = cell(0,4);      % ���� ���̺� ����� ����, ù��° �� / �ι�° �� / ���̺� �̸� / ���̺� ���� ����
    
    vesselState = 1;        % Artery / Vein state
    

    % create GUI
    h = initGUI();

    function h = initGUI()
        scr = get(groot,'ScreenSize');
        h.fig = figure('Name','Vessel Graph', 'Resize','off', 'Position', ...
            [((scr(3)-980)/2) ((scr(4)-840)/2) 980 840]);
        h.ax = axes('Parent',h.fig, 'ButtonDownFcn',@onMouseDown, ...
            'XLim',[0 1000], 'YLim',[0 1000], 'XTick',[], 'YTick',[], 'Box','on', ...
            'Units','pixels', 'Position',[160 20 800 800]);

        %radio code move
        h.rA = uicontrol('Style','radiobutton', 'Parent',h.fig, 'String','Artery', ...
            'Position',[20 800 60 20],'Value',1,'Callback',@onArtery);
        h.rV = uicontrol('Style','radiobutton', 'Parent',h.fig, 'String','Vein', ...
            'Position',[90 800 60 20],'Callback',@onVein);
        h.list = uicontrol('Style','listbox', 'Parent',h.fig, 'String',{}, ...
            'Min',1, 'Max',1, 'Value',1, 'FontName', 'Fixedsys', 'FontSize', 10, ...
            'Position',[20 170 130 620], 'Callback',@onSelect); % 140
        h.lable_text = uicontrol('Style','text', 'Parent',h.fig, 'String',{}, ...
            'String', '�̸�:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 140 40 20]);
        h.lable_edit = uicontrol('Style','edit', 'Parent',h.fig, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 140 60 20]);
        h.labelSet = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','����', ...
            'Position',[125 140 25 20], 'Callback',@onLabelSet, 'Enable', 'off');
        h.delete = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','��/���� ����', ...
            'Position',[20 110 130 20], 'Callback',@onDelete, 'Enable', 'off');
        h.clear = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','�ʱ�ȭ', ...
            'Position',[20 80 130 20], 'Callback',@onClear);
        h.import = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','��������', ...
            'Position',[20 50 130 20], 'Callback',@onImport);
        h.export = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','��������', ...
            'Position',[20 20 130 20], 'Callback',@onExport);


        
        h.cmenu = uicontextmenu('Parent',h.fig);
        h.menu = uimenu(h.cmenu, 'Label','Show verticies', 'Checked','off', ...
            'Callback',@onCMenu);
        set(h.list, 'UIContextMenu',h.cmenu)

        % ���� (Atery)
        % ������.. �������� ���ν�Ÿ���� None���� �ؼ� ���� �ȱ׸��� Marker�� ��� ��.
        h.pts = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % ���콺 ������ ��ư���� ���� ���� �� ��� �׵θ� - ���� �׸��� ����
        h.prev = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % ���� ���
        h.edges = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
        % ������ �󺧸� ǥ�ÿ� ����(���� �ƴ�). V1, V2, ... �������
        h.vertices = [];
        % ���� �󺧸� ǥ�ÿ� ����(���� �ƴ�). E1, E2, ... �������
        h.vessels = [];
        
        
        % ���� (Vein)
        % ������.. �������� ���ν�Ÿ���� None���� �ؼ� ���� �ȱ׸��� Marker�� ��� ��.
        h.ptsV = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
        % ���콺 ������ ��ư���� ���� ���� �� ��� �׵θ� - ���� �׸��� ����
        h.prevV = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % ���� ���
        h.edgesV = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','b');
        % ������ �󺧸� ǥ�ÿ� ����(���� �ƴ�). V1, V2, ... �������
        h.verticesV = [];
        % ���� �󺧸� ǥ�ÿ� ����(���� �ƴ�). E1, E2, ... �������
        h.vesselsV = [];
    end

    function onArtery(~,~)
        h.rV.Value = ~h.rA.Value;
        setCategory()
    end

    function onVein(~,~)
        h.rA.Value = ~h.rV.Value;
        setCategory()
    end

    function setCategory()
        if h.rA.Value == 1
            vesselState = 1;
            prevIdxV = [];
            selectIdxV = [];
        else    %h.rV.Value == 1
            vesselState = 0;
            prevIdx = [];
            selectIdx = [];
        end
        
        set(h.lable_edit, 'String', '')
        set(h.lable_edit, 'Enable', 'off')
        set(h.labelSet, 'Enable', 'off')
        set(h.delete, 'Enable', 'off')
        redraw()
    end

    function onMouseDown(~,~)
        % get location of mouse click (in data coordinates)
        if strcmp(get(h.lable_edit, 'Enable'), 'on')
            set(h.lable_edit, 'String', '')
            set(h.lable_edit, 'Enable', 'off')
        end
        
        p = get(h.ax, 'CurrentPoint');

        if vesselState == 1
            % ���� ó�� (Atery)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                pts(end+1,:) = p(1,1:2);
                adj(end+1,end+1) = 0;
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+���콺 ���� Ŭ��
                onLabelEdit();
            else
                % hit test (find node closest to click location: euclidean distnce)
                [dst,idx] = min(sum(bsxfun(@minus, pts, p(1,1:2)).^2,2));
                if sqrt(dst) > 8, return; end
                set(h.delete, 'Enable', 'on')

                if isempty(prevIdx)
                    % starting node (requires a second click to finish)
                    prevIdx = idx;
                else
                    % add the new edge % ���� ���� �ܰ�
                    if adj(prevIdx,idx) ~= 1 && adj(idx,prevIdx) ~= 1
                        adj(prevIdx,idx) = 1;
                        m = size(label,1);
                        label{m+1,1} = prevIdx;
                        label{m+1,2} = idx;
                        label{m+1,3} = strcat('E', num2str(m+1));
                    else
                        % warndlg('�� ���� �̹� ����Ǿ����ϴ�.','����')
                    end
                    prevIdx = [];
                    set(h.delete, 'Enable', 'off')
                end
            end
        else
            % ���� ó�� (Vein) 
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                ptsV(end+1,:) = p(1,1:2);
                adjV(end+1,end+1) = 0;
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+���콺 ���� Ŭ��
                onLabelEdit();
            else
                % hit test (find node closest to click location: euclidean distnce)
                [dst,idx] = min(sum(bsxfun(@minus, ptsV, p(1,1:2)).^2,2));
                if sqrt(dst) > 8, return; end
                set(h.delete, 'Enable', 'on')

                if isempty(prevIdxV)
                    % starting node (requires a second click to finish)
                    prevIdxV = idx;
                else
                    % add the new edge % ���� ���� �ܰ�
                    if adjV(prevIdxV,idx) ~= 1 && adjV(idx,prevIdxV) ~= 1
                        adjV(prevIdxV,idx) = 1;
                        m = size(labelV,1);
                        labelV{m+1,1} = prevIdxV;
                        labelV{m+1,2} = idx;
                        labelV{m+1,3} = strcat('E', num2str(m+1));
                    else
                        % warndlg('�� ���� �̹� ����Ǿ����ϴ�.','����')
                    end
                    prevIdxV = [];
                    set(h.delete, 'Enable', 'off')
                end
            end
        end

        % update GUI
        selectIdx = [];
        selectIdxV = [];
        redraw()
    end

    function onDelete(~,~)
        % check that list of nodes is not empty
        if isempty(pts) && isempty(ptsV), return; end

        % delete selected node
        if vesselState
            if ~isempty(prevIdx)             % ���콺 ������ Ŭ�����θ� Vertex ����.
                idx = prevIdx;
    %            prevIdx = [];              %�ؿ��� �ʱ�ȭ �ϴ� ���ʿ� �����

                % ������ ���� �ܰ�
                pts(idx,:) = [];

                % ���� ���� �ܰ� (�������� ����� ���� ���)
                adj(:,idx) = [];
                adj(idx,:) = [];

                rowList = [];
                for q = 1:size(label,1)
                    if label{q,1} == idx || label{q,2} == idx
                        rowList = [rowList q];
                    end
                end
                label(rowList,:) = [];
                for q = 1:size(label,1)
                    if label{q,1} > idx
                        label{q,1} = label{q,1}-1;
                    end

                    if label{q,2} > idx
                        label{q,2} = label{q,2}-1;
                    end

                    if isempty(label{q,4}) || label{q,4} == 0
                        label{q,3} = ['E' num2str(q)];
                    end
                end

            else
                idx = get(h.list, 'Value');     % ���и� ���� �� (�������� �״��)
                adj(label{idx,1}, label{idx,2}) = 0;
                label(idx,:) = [];

                for q = 1:size(label,1)                
                    if isempty(label{q,4}) || label{q,4} == 0
                        label{q,3} = ['E' num2str(q)];
                    end
                end
            end


            % clear previous selections
            if prevIdx == idx
                prevIdx = [];
            end
            selectIdx = [];

            if strcmp(get(h.lable_edit, 'Enable'), 'on')
                set(h.lable_edit, 'String', '')
                set(h.lable_edit, 'Enable', 'off')
            end

            if strcmp(get(h.labelSet, 'Enable'), 'on')
                set(h.labelSet, 'Enable', 'off')
            end
            
        else
            if ~isempty(prevIdxV)             % ���콺 ������ Ŭ�����θ� Vertex ����.
                idx = prevIdxV;
    %            prevIdx = [];              %�ؿ��� �ʱ�ȭ �ϴ� ���ʿ� �����

                % ������ ���� �ܰ�
                ptsV(idx,:) = [];

                % ���� ���� �ܰ� (�������� ����� ���� ���)
                adjV(:,idx) = [];
                adjV(idx,:) = [];

                rowList = [];
                for q = 1:size(labelV,1)
                    if labelV{q,1} == idx || labelV{q,2} == idx
                        rowList = [rowList q];
                    end
                end
                labelV(rowList,:) = [];
                for q = 1:size(labelV,1)
                    if labelV{q,1} > idx
                        labelV{q,1} = labelV{q,1}-1;
                    end

                    if labelV{q,2} > idx
                        labelV{q,2} = labelV{q,2}-1;
                    end

                    if isempty(labelV{q,4}) || labelV{q,4} == 0
                        labelV{q,3} = ['E' num2str(q)];
                    end
                end

            else
                idx = get(h.list, 'Value');     % ���и� ���� �� (�������� �״��)
                adj(labelV{idx,1}, labelV{idx,2}) = 0;
                labelV(idx,:) = [];

                for q = 1:size(labelV,1)                
                    if isempty(labelV{q,4}) || labelV{q,4} == 0
                        labelV{q,3} = ['E' num2str(q)];
                    end
                end
            end


            % clear previous selections
            if prevIdxV == idx
                prevIdxV = [];
            end
            selectIdxV = [];

            if strcmp(get(h.lable_edit, 'Enable'), 'on')
                set(h.lable_edit, 'String', '')
                set(h.lable_edit, 'Enable', 'off')
            end

            if strcmp(get(h.labelSet, 'Enable'), 'on')
                set(h.labelSet, 'Enable', 'off')
            end
        end

        % update GUI
        set(h.list, 'Value',1)
        set(h.delete, 'Enable', 'off')
        redraw()
    end

    function onClear(~,~)
        % reset everything
        prevIdx = [];
        selectIdx = [];
        pts = zeros(0,2);
        adj = sparse([]);
        label = cell(0,3);      % label ���� ���� ���� �߰�
        
        prevIdxV = [];
        selectIdxV = [];
        ptsV = zeros(0,2);
        adjV = sparse([]);
        labelV = cell(0,3);      % label ���� ���� ���� �߰�

        % update GUI
        set(h.list, 'Value',1)
        redraw()
    end

    function onExport(~,~)
        fname = datestr(now,'yymmddHHMMSS');
        uisave({'pts', 'adj', 'label', 'ptsV', 'adjV', 'labelV'}, ['VG_' fname]);
    end

    function onImport(~,~)
        [FileName,PathName] = uigetfile('*.mat','������ MATLAB �׷��� ����(.mat)�� �����ϼ���.');
        onClear();
        finput = load(FileName);
        
        pts = finput.pts;
        adj = finput.adj;
        label = finput.label;
        
        ptsV = finput.ptsV;
        adjV = finput.adjV;
        labelV = finput.labelV;
        
        redraw();
    end

    function onSelect(~,~)
        % update index of currently selected node
        prevIdx = [];
        prevIdxV = [];
        if size(get(h.list, 'String'), 1) == 0, return; end
        
        if vesselState
            selectIdx = get(h.list, 'Value');
            set(h.lable_edit, 'String', label{selectIdx, 3})
        else
            selectIdxV = get(h.list, 'Value');
            set(h.lable_edit, 'String', labelV{selectIdxV, 3})
        end
        
        set(h.lable_edit, 'Enable', 'on')
        set(h.delete, 'Enable', 'on')
        set(h.labelSet, 'Enable', 'on')
        redraw()
    end

    function onCMenu(~,~)
        % flip state
        showVertices = ~showVertices;
        redraw()
    end

    function onLabelEdit(~,~)
        set(h.lable_edit, 'Enable', 'on');
    end

    function onLabelSet(~,~)
        if strcmp(set(h.lable_edit, 'Enable'), 'off'), return; end
        
        if vesselState
            label{selectIdx,3} = get(h.lable_edit, 'String');
            label{selectIdx,4} = 1;
        else
            labelV{selectIdxV,3} = get(h.lable_edit, 'String');
            labelV{selectIdxV,4} = 1;
        end
        
        selectIdx = [];
        selectIdxV = [];
        set(h.lable_edit, 'String', '')
        set(h.lable_edit, 'Enable', 'off')
        set(h.labelSet, 'Enable', 'off')
        redraw()
    end

    function redraw()
        % ���� �׸��� �ܰ�
        % ����
        p = nan(3*nnz(adj),2);
        for q = 1:size(label,1)
            p(1+3*(q-1),:) = pts(label{q,1},:);
            p(2+3*(q-1),:) = pts(label{q,2},:);
        end
        set(h.edges, 'XData',p(:,1), 'YData',p(:,2))
        if ishghandle(h.vessels), delete(h.vessels); end
        h.vessels = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
             strcat(label(:,3)), ...  % label(:)
             'HitTest','off', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold', ...
             'VerticalAlign','bottom', 'HorizontalAlign','left');
        % ����
        p = nan(3*nnz(adjV),2);
        for q = 1:size(labelV,1)
            p(1+3*(q-1),:) = ptsV(labelV{q,1},:);
            p(2+3*(q-1),:) = ptsV(labelV{q,2},:);
        end
        set(h.edgesV, 'XData',p(:,1), 'YData',p(:,2))
        if ishghandle(h.vesselsV), delete(h.vesselsV); end
        h.vesselsV = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
             strcat(labelV(:,3)), ...  % labelV(:)
             'HitTest','off', 'FontSize', 10, 'Color', 'b', 'FontWeight', 'bold', ...
             'VerticalAlign','bottom', 'HorizontalAlign','left');

        % �� �׸��� �ܰ�
        % ����
        set(h.pts, 'XData', pts(:,1), 'YData',pts(:,2))
        set(h.prev, 'XData', pts(prevIdx,1), 'YData',pts(prevIdx,2))
        if ~isempty(selectIdx)
            set(h.vessels(selectIdx), 'Color', 'y')
        end       
        % ����
        set(h.ptsV, 'XData', ptsV(:,1), 'YData',ptsV(:,2))
        set(h.prevV, 'XData', ptsV(prevIdxV,1), 'YData', ptsV(prevIdxV,2))
        if ~isempty(selectIdxV)
            set(h.vesselsV(selectIdxV), 'Color', 'y')
        end
        
        % ���� �̸� (����) ��� ���
        if vesselState
            % ���� �̸� ���
            set(h.list, 'String', strcat(num2str((1:size(label,1))'), ': ', label(:,3)))
        else
            % ���� �̸� ���
            set(h.list, 'String', strcat(num2str((1:size(labelV,1))'), ': ', labelV(:,3)))
        end

        % ������ �̸� ���
        % ����
        if ishghandle(h.vertices), delete(h.vertices); end
        if showVertices
            set(h.menu, 'Checked','on')
            h.vertices = text(pts(:,1)+2.5, pts(:,2)+2.5, ...
                strcat('V', num2str((1:size(pts,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', 'b', 'FontWeight', 'bold', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left');
        else
            set(h.menu, 'Checked','off')
        end
        % ����
        if ishghandle(h.verticesV), delete(h.verticesV); end
        if showVertices
            set(h.menu, 'Checked','on')
            h.verticesV = text(ptsV(:,1)+2.5, ptsV(:,2)+2.5, ...
                strcat('V', num2str((1:size(ptsV,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', 'r', 'FontWeight', 'bold', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left');
        else
            set(h.menu, 'Checked','off')
        end

        % force refresh
        drawnow
    end

end
