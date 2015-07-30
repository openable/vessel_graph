function VGE
    % data
    showVertices = true;   % flag to determine whether to show node labels

    prevIdxAtery = [];         % keeps track of 1st node clicked in creating edges
    selectIdxAtery = [];       % used to highlight node selected in listbox

    ptsAtery = zeros(0,2);     % x/y coordinates of vertices
    adjAtery = sparse([]);     % sparse adjacency matrix (undirected)    % ���� ���� ���� ���
    labelAtery = cell(0,4);      % ���� �� ����� ����, ù��° �� / �ι�° �� / ���̺� �̸� / ���̺� ���� ����

    prevIdxVein = [];
    selectIdxVein = [];
    
    ptsVein = zeros(0,2);     % x/y coordinates of vertices
    adjVein = sparse([]);     % sparse adjacency matrix (undirected)    % ���� ���� ���� ���
    labelVein = cell(0,4);      % ���� �� ����� ����, ù��° �� / �ι�° �� / ���̺� �̸� / ���̺� ���� ����
    
    vesselState = 1;        % Artery (1) / Vein (0) state
    

    % create GUI
    h = initGUI();

    function h = initGUI()
        scr = get(groot,'ScreenSize');
        h.fig = figure('Name','Vessel Graph', 'Resize','off', 'Position', ...
            [((scr(3)-980)/2) ((scr(4)-840)/2) 980 860], 'KeyPressFcn',@onFigKey);
        h.tgroup = uitabgroup('Parent', h.fig);
        h.tab1 = uitab('Parent', h.tgroup, 'Title', '2D');
        h.tab2 = uitab('Parent', h.tgroup, 'Title', '3D');
        
        h.ax = axes('Parent',h.tab1, 'ButtonDownFcn',@onMouseDown, ...
            'XLim',[0 1000], 'YLim',[0 1000], 'XTick',[], 'YTick',[], 'Box','on', ...
            'Units','pixels', 'Position',[160 20 800 800]);

        %radio code move
        h.rA = uicontrol('Style','radiobutton', 'Parent',h.tab1, 'String','Artery', ...
            'Position',[20 800 60 20],'Value',1,'Callback',@onArtery);
        h.rV = uicontrol('Style','radiobutton', 'Parent',h.tab1, 'String','Vein', ...
            'Position',[90 800 60 20],'Callback',@onVein);
        h.list = uicontrol('Style','listbox', 'Parent',h.tab1, 'String',{}, ...
            'Min',1, 'Max',1, 'Value',-1, 'FontName', 'Fixedsys', 'FontSize', 10, ...
            'Position',[20 170 130 620], 'Callback',@onSelect); % 140
        h.labelText = uicontrol('Style','text', 'Parent',h.tab1, 'String',{}, ...
            'String', '�̸�:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 140 40 20]);
        h.labelEdit = uicontrol('Style','edit', 'Parent',h.tab1, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 140 60 20], 'KeyPressFcn',@onEditKey);
        h.labelSet = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','����', ...
            'Position',[125 140 25 20], 'Callback',@onLabelSet, 'Enable', 'off', 'KeyPressFcn',@onSetKey);
        h.delete = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','��/���� ����', ...
            'Position',[20 110 130 20], 'Callback',@onDelete, 'Enable', 'off');
        h.clear = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','�ʱ�ȭ', ...
            'Position',[20 80 130 20], 'Callback',@onClear);
        h.import = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','��������', ...
            'Position',[20 50 130 20], 'Callback',@onImport);
        h.export = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','��������', ...
            'Position',[20 20 130 20], 'Callback',@onExport);


        
        h.cmenu = uicontextmenu('Parent',h.fig);
        h.menu = uimenu(h.cmenu, 'Label','Show verticies', 'Checked','off', ...
            'Callback',@onCMenu);
        set(h.list, 'UIContextMenu',h.cmenu)

        % ���� (Atery)
        % ������.. �������� ���ν�Ÿ���� None���� �ؼ� ���� �ȱ׸��� Marker�� ��� ��.
        h.ptsAtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
        % ���콺 ������ ��ư���� ���� ���� �� ��� �׵θ� - ���� �׸��� ����
        h.prevAtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % ���� ���
        h.edgesAtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
        % ������ �󺧸� ǥ�ÿ� ����(���� �ƴ�). V1, V2, ... �������
        h.verticesAtery = [];
        % ���� �󺧸� ǥ�ÿ� ����(���� �ƴ�). E1, E2, ... �������
        h.vesselsAtery = [];
        
        
        % ���� (Vein)
        % ������.. �������� ���ν�Ÿ���� None���� �ؼ� ���� �ȱ׸��� Marker�� ��� ��.
        h.ptsVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % ���콺 ������ ��ư���� ���� ���� �� ��� �׵θ� - ���� �׸��� ����
        h.prevVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % ���� ���
        h.edgesVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','b');
        % ������ �󺧸� ǥ�ÿ� ����(���� �ƴ�). V1, V2, ... �������
        h.verticesVein = [];
        % ���� �󺧸� ǥ�ÿ� ����(���� �ƴ�). E1, E2, ... �������
        h.vesselsAteryV = [];
    end

    function onFigKey(~,~)
        % Figure â���� ESC Ű���� �Է½� ����
        key = get(h.fig,'CurrentCharacter');
 
        if isequal(key,char(27))
            prevIdxAtery = [];
            prevIdxVein = [];
            selectIdxAtery = [];
            selectIdxVein = [];
            
            set(h.labelEdit, 'String', '')
            set(h.labelEdit, 'Enable', 'off')
            set(h.labelSet, 'Enable', 'off')
            set(h.delete, 'Enable', 'off')
            redraw()
        end
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
            prevIdxVein = [];
            selectIdxVein = [];
        else    %h.rV.Value == 1
            vesselState = 0;
            prevIdxAtery = [];
            selectIdxAtery = [];
        end
        
        set(h.labelEdit, 'String', '')
        set(h.labelEdit, 'Enable', 'off')
        set(h.labelSet, 'Enable', 'off')
        set(h.delete, 'Enable', 'off')
        redraw()
    end

    function onMouseDown(~,~)
        % get location of mouse click (in data coordinates)
        if strcmp(get(h.labelEdit, 'Enable'), 'on')
            set(h.labelEdit, 'String', '')
            set(h.labelEdit, 'Enable', 'off')
        end
        
        p = get(h.ax, 'CurrentPoint');

        if vesselState == 1
            % ���� ó�� (Atery)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                ptsAtery(end+1,:) = p(1,1:2);
                adjAtery(end+1,end+1) = 0;
                
                selectIdxAtery = [];
                selectIdxVein = [];
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+���콺 ���� Ŭ��
                if size(labelAtery,1) < 1, return; end
                labelPts = getLabelPts(ptsAtery, labelAtery);
                [dst,idx] = min(sum(bsxfun(@minus, labelPts, p(1,1:2)).^2,2));

                if sqrt(dst) > 20, selectIdxAtery = []; setCategory(); return; end
                onLabelEdit(idx);
            else
                % hit test (find node closest to click location: euclidean distnce)
                [dst,idx] = min(sum(bsxfun(@minus, ptsAtery, p(1,1:2)).^2,2));
                if sqrt(dst) > 8, return; end
                set(h.delete, 'Enable', 'on')

                if isempty(prevIdxAtery)
                    % starting node (requires a second click to finish)
                    prevIdxAtery = idx;
                else
                    % add the new edge % ���� ���� �ܰ�
                    if adjAtery(prevIdxAtery,idx) ~= 1 && adjAtery(idx,prevIdxAtery) ~= 1
                        adjAtery(prevIdxAtery,idx) = 1;
                        m = size(labelAtery,1);
                        labelAtery{m+1,1} = prevIdxAtery;
                        labelAtery{m+1,2} = idx;
                        labelAtery{m+1,3} = strcat('A', num2str(m+1));
                    else
                        % warndlg('�� ���� �̹� ����Ǿ����ϴ�.','����')
                    end
                    prevIdxAtery = [];
                    set(h.delete, 'Enable', 'off')
                end
                
                selectIdxAtery = [];
                selectIdxVein = [];
            end
        else
            % ���� ó�� (Vein) 
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                ptsVein(end+1,:) = p(1,1:2);
                adjVein(end+1,end+1) = 0;
                
                selectIdxAtery = [];
                selectIdxVein = [];
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+���콺 ���� Ŭ��
                if size(labelVein,1) < 1, return; end
                labelPts = getLabelPts(ptsVein, labelVein);
                [dst,idx] = min(sum(bsxfun(@minus, labelPts, p(1,1:2)).^2,2));

                if sqrt(dst) > 20, selectIdxVein = []; setCategory(); return; end
                onLabelEdit(idx);
            else
                % hit test (find node closest to click location: euclidean distnce)
                [dst,idx] = min(sum(bsxfun(@minus, ptsVein, p(1,1:2)).^2,2));
                if sqrt(dst) > 8, return; end
                set(h.delete, 'Enable', 'on')

                if isempty(prevIdxVein)
                    % starting node (requires a second click to finish)
                    prevIdxVein = idx;
                else
                    % add the new edge % ���� ���� �ܰ�
                    if adjVein(prevIdxVein,idx) ~= 1 && adjVein(idx,prevIdxVein) ~= 1
                        adjVein(prevIdxVein,idx) = 1;
                        m = size(labelVein,1);
                        labelVein{m+1,1} = prevIdxVein;
                        labelVein{m+1,2} = idx;
                        labelVein{m+1,3} = strcat('V', num2str(m+1));
                    else
                        % warndlg('�� ���� �̹� ����Ǿ����ϴ�.','����')
                    end
                    prevIdxVein = [];
                    set(h.delete, 'Enable', 'off')
                end
                
                selectIdxAtery = [];
                selectIdxVein = [];
            end
        end

        % update GUI
        redraw()
    end

    function mat = getLabelPts(pts, label)
        mat = zeros(size(label,1),2);
        for n = 1:size(label,1)
            % x�� ��ǥ�� 10�� �Ϻη� �Ű���. �� ����� ���� ���ķ� ������ ����.
            mat(n,1) = (pts(label{n,1},1) + pts(label{n,2},1))/2 + 8 + 10;
            mat(n,2) = (pts(label{n,1},2) + pts(label{n,2},2))/2 + 8;
        end
    end

    function onDelete(~,~)
        % check that list of nodes is not empty
        if isempty(ptsAtery) && isempty(ptsVein), return; end

        % delete selected node
        if vesselState
            if ~isempty(prevIdxAtery)             % ���콺 ������ Ŭ�����θ� Vertex ����.
                idx = prevIdxAtery;
    %            prevIdx = [];              %�ؿ��� �ʱ�ȭ �ϴ� ���ʿ� �����

                % ������ ���� �ܰ�
                ptsAtery(idx,:) = [];

                % ���� ���� �ܰ� (�������� ����� ���� ���)
                adjAtery(:,idx) = [];
                adjAtery(idx,:) = [];

                rowList = [];
                for q = 1:size(labelAtery,1)
                    if labelAtery{q,1} == idx || labelAtery{q,2} == idx
                        rowList = [rowList q];
                    end
                end
                labelAtery(rowList,:) = [];
                for q = 1:size(labelAtery,1)
                    if labelAtery{q,1} > idx
                        labelAtery{q,1} = labelAtery{q,1}-1;
                    end

                    if labelAtery{q,2} > idx
                        labelAtery{q,2} = labelAtery{q,2}-1;
                    end

                    if isempty(labelAtery{q,4}) || labelAtery{q,4} == 0
                        labelAtery{q,3} = ['A' num2str(q)];
                    end
                end

            else
                idx = get(h.list, 'Value');     % ���и� ���� �� (�������� �״��)
                adjAtery(labelAtery{idx,1}, labelAtery{idx,2}) = 0;
                labelAtery(idx,:) = [];

                for q = 1:size(labelAtery,1)                
                    if isempty(labelAtery{q,4}) || labelAtery{q,4} == 0
                        labelAtery{q,3} = ['A' num2str(q)];
                    end
                end
            end


            % clear previous selections
            if prevIdxAtery == idx
                prevIdxAtery = [];
            end
            selectIdxAtery = [];

            if strcmp(get(h.labelEdit, 'Enable'), 'on')
                set(h.labelEdit, 'String', '')
                set(h.labelEdit, 'Enable', 'off')
            end

            if strcmp(get(h.labelSet, 'Enable'), 'on')
                set(h.labelSet, 'Enable', 'off')
            end
            
        else
            if ~isempty(prevIdxVein)             % ���콺 ������ Ŭ�����θ� Vertex ����.
                idx = prevIdxVein;

                % ������ ���� �ܰ�
                ptsVein(idx,:) = [];

                % ���� ���� �ܰ� (�������� ����� ���� ���)
                adjVein(:,idx) = [];
                adjVein(idx,:) = [];

                rowList = [];
                for q = 1:size(labelVein,1)
                    if labelVein{q,1} == idx || labelVein{q,2} == idx
                        rowList = [rowList q];
                    end
                end
                labelVein(rowList,:) = [];
                for q = 1:size(labelVein,1)
                    if labelVein{q,1} > idx
                        labelVein{q,1} = labelVein{q,1}-1;
                    end

                    if labelVein{q,2} > idx
                        labelVein{q,2} = labelVein{q,2}-1;
                    end

                    if isempty(labelVein{q,4}) || labelVein{q,4} == 0
                        labelVein{q,3} = ['V' num2str(q)];
                    end
                end

            else
                idx = get(h.list, 'Value');     % ���и� ���� �� (�������� �״��)
                adjVein(labelVein{idx,1}, labelVein{idx,2}) = 0;
                labelVein(idx,:) = [];

                for q = 1:size(labelVein,1)                
                    if isempty(labelVein{q,4}) || labelVein{q,4} == 0
                        labelVein{q,3} = ['V' num2str(q)];
                    end
                end
            end


            % clear previous selections
            if prevIdxVein == idx
                prevIdxVein = [];
            end
            selectIdxVein = [];

            if strcmp(get(h.labelEdit, 'Enable'), 'on')
                set(h.labelEdit, 'String', '')
                set(h.labelEdit, 'Enable', 'off')
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
        prevIdxAtery = [];
        selectIdxAtery = [];
        ptsAtery = zeros(0,2);
        adjAtery = sparse([]);
        labelAtery = cell(0,3);      % label ���� ���� ���� �߰�
        
        prevIdxVein = [];
        selectIdxVein = [];
        ptsVein = zeros(0,2);
        adjVein = sparse([]);
        labelVein = cell(0,3);      % label ���� ���� ���� �߰�

        % update GUI
        set(h.labelEdit, 'String', '')
        set(h.labelEdit, 'Enable', 'off')
        set(h.labelSet, 'Enable', 'off')
        set(h.delete, 'Enable', 'off')
        set(h.list, 'Value', -1)
        redraw()
    end

    function onExport(~,~)
        fname = datestr(now,'yymmddHHMMSS');
        uisave({'ptsAtery', 'adjAtery', 'labelAtery', 'ptsVein', 'adjVein', 'labelVein'}, ['VG_' fname]);
    end

    function onImport(~,~)
        FileName = uigetfile('*.mat','������ MATLAB �׷��� ����(.mat)�� �����ϼ���.');
        onClear();
        finput = load(FileName);
        
        ptsAtery = finput.ptsAtery;
        adjAtery = finput.adjAtery;
        labelAtery = finput.labelAtery;
        
        ptsVein = finput.ptsVein;
        adjVein = finput.adjVein;
        labelVein = finput.labelVein;
        
        set(h.list, 'Value', 1)
        redraw();
    end

    function onSelect(~,~)
        % update index of currently selected node
        prevIdxAtery = [];
        prevIdxVein = [];
        
        % ����Ʈ �ڽ��� ����� �� (�ʱ� ����, �����ϴٰ� ��� ������ ����) Value �� ����
        if ~isempty(get(h.list, 'String'))
            if vesselState
                selectIdxAtery = get(h.list, 'Value');
                set(h.labelEdit, 'String', labelAtery{selectIdxAtery, 3})
            else
                selectIdxVein = get(h.list, 'Value');
                set(h.labelEdit, 'String', labelVein{selectIdxVein, 3})
            end

            set(h.labelEdit, 'Enable', 'on')
            set(h.delete, 'Enable', 'on')
            set(h.labelSet, 'Enable', 'on')
        else
            set(h.list, 'Value', -1)
        end
        
        % ���� �� ���� text editor�� Ŀ�� �ڵ� ��ġ
        uicontrol(h.labelEdit);
        redraw()
    end

    function onCMenu(~,~)
        % flip state
        showVertices = ~showVertices;
        redraw()
    end

    function onLabelEdit(idx)
        prevIdxAtery = [];
        prevIdxVein = [];
        
        if vesselState
            selectIdxAtery = idx;
            set(h.labelEdit, 'String', labelAtery{selectIdxAtery, 3})
        else
            selectIdxVein = idx;
            set(h.labelEdit, 'String', labelVein{selectIdxVein, 3})
        end
        
        set(h.list, 'Value', idx)
        set(h.labelEdit, 'Enable', 'on')
        set(h.delete, 'Enable', 'on')
        set(h.labelSet, 'Enable', 'on')
        uicontrol(h.labelEdit);
        redraw()
    end

    function onLabelSet(~,~)
        if strcmp(set(h.labelEdit, 'Enable'), 'off'), return; end
        
        if vesselState
            labelAtery{selectIdxAtery,3} = get(h.labelEdit, 'String');
            labelAtery{selectIdxAtery,4} = 1;
        else
            labelVein{selectIdxVein,3} = get(h.labelEdit, 'String');
            labelVein{selectIdxVein,4} = 1;
        end
        
        selectIdxAtery = [];
        selectIdxVein = [];
        set(h.labelEdit, 'String', '')
        set(h.labelEdit, 'Enable', 'off')
        set(h.labelSet, 'Enable', 'off')
        redraw()
    end

    function onEditKey(~,~)
        % text edit â���� Enter, ESC Ű���� �Է½� ����
        key = get(h.fig,'CurrentCharacter');

        if isequal(key,char(13))
            % ��Ŀ���� ���� set ��ư���� �̵�, �׷��� ���� ���� ���� �ݿ� ��
            uicontrol(h.labelSet);
            onLabelSet();
        elseif isequal(key,char(27))
            selectIdxAtery = [];
            selectIdxVein = [];
            uicontrol(h.labelSet);
            setCategory();
        end
    end

    function onSetKey(~,~)
        % set ��ư ��Ŀ�� �� Enter, ESC Ű���� �Է½� ����
        key = get(h.fig,'CurrentCharacter');
 
        if isequal(key,char(13))
            onLabelSet();
        elseif isequal(key,char(27))
            selectIdxAtery = [];
            selectIdxVein = [];
            setCategory();
        end
    end

    function redraw()
        % ���� �׸��� �ܰ�
        % ����
        p = nan(3*nnz(adjAtery),2);
        for q = 1:size(labelAtery,1)
            p(1+3*(q-1),:) = ptsAtery(labelAtery{q,1},:);
            p(2+3*(q-1),:) = ptsAtery(labelAtery{q,2},:);
        end
        set(h.edgesAtery, 'XData',p(:,1), 'YData',p(:,2))
        if ishghandle(h.vesselsAtery), delete(h.vesselsAtery); end
        h.vesselsAtery = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
             strcat(labelAtery(:,3)), ...  % label(:)
             'HitTest','off', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold', ...
             'VerticalAlign','bottom', 'HorizontalAlign','left');
        if ~isempty(selectIdxAtery)
            set(h.vesselsAtery(selectIdxAtery), 'Color', 'g')
        end   
        % ����
        p = nan(3*nnz(adjVein),2);
        for q = 1:size(labelVein,1)
            p(1+3*(q-1),:) = ptsVein(labelVein{q,1},:);
            p(2+3*(q-1),:) = ptsVein(labelVein{q,2},:);
        end
        set(h.edgesVein, 'XData',p(:,1), 'YData',p(:,2))
        if ishghandle(h.vesselsAteryV), delete(h.vesselsAteryV); end
        h.vesselsAteryV = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
             strcat(labelVein(:,3)), ...  % labelV(:)
             'HitTest','off', 'FontSize', 10, 'Color', 'b', 'FontWeight', 'bold', ...
             'VerticalAlign','bottom', 'HorizontalAlign','left');
        if ~isempty(selectIdxVein)
            set(h.vesselsAteryV(selectIdxVein), 'Color', 'g')
        end
         
        % �� �׸��� �ܰ�
        % ����
        set(h.ptsAtery, 'XData', ptsAtery(:,1), 'YData',ptsAtery(:,2))
        set(h.prevAtery, 'XData', ptsAtery(prevIdxAtery,1), 'YData',ptsAtery(prevIdxAtery,2))
    
        % ����
        set(h.ptsVein, 'XData', ptsVein(:,1), 'YData',ptsVein(:,2))
        set(h.prevVein, 'XData', ptsVein(prevIdxVein,1), 'YData', ptsVein(prevIdxVein,2))
        
        % ���� �̸� (����) ��� ���
        if vesselState
            if size(labelAtery,1) == 1, set(h.list, 'Value', 1); end
            % ���� �̸� ���
            set(h.list, 'String', strcat(num2str((1:size(labelAtery,1))'), ': ', labelAtery(:,3)))
        else
            if size(labelVein,1) == 1, set(h.list, 'Value', 1); end
            % ���� �̸� ���
            set(h.list, 'String', strcat(num2str((1:size(labelVein,1))'), ': ', labelVein(:,3)))
        end

        % ������ �̸� ���
        % ����
        if ishghandle(h.verticesAtery), delete(h.verticesAtery); end
        if showVertices
            set(h.menu, 'Checked','on')
            h.verticesAtery = text(ptsAtery(:,1)+2.5, ptsAtery(:,2)+2.5, ...
                strcat('a', num2str((1:size(ptsAtery,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', [0.1,0.1,0.1]*7, 'FontWeight', 'normal', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left');
        else
            set(h.menu, 'Checked','off')
        end
        % ����
        if ishghandle(h.verticesVein), delete(h.verticesVein); end
        if showVertices
            set(h.menu, 'Checked','on')
            h.verticesVein = text(ptsVein(:,1)+2.5, ptsVein(:,2)+2.5, ...
                strcat('v', num2str((1:size(ptsVein,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', [0.1,0.1,0.1]*7, 'FontWeight', 'normal', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left');
        else
            set(h.menu, 'Checked','off')
        end

        % force refresh
        drawnow
    end

end
