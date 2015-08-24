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



prevIdxAtery3D = [];         % keeps track of 1st node clicked in creating edges
selectIdxAtery3D = [];       % used to highlight node selected in listbox

ptsAtery3D = zeros(0,3);     % x/y coordinates of vertices
adjAtery3D = sparse([]);     % sparse adjacency matrix (undirected)    % ���� ���� ���� ���
labelAtery3D = cell(0,4);      % ���� �� ����� ����, ù��° �� / �ι�° �� / ���̺� �̸� / ���̺� ���� ����

prevIdxVein3D = [];
selectIdxVein3D = [];

ptsVein3D = zeros(0,3);     % x/y coordinates of vertices
adjVein3D = sparse([]);     % sparse adjacency matrix (undirected)    % ���� ���� ���� ���
labelVein3D = cell(0,4);      % ���� �� ����� ����, ù��° �� / �ι�° �� / ���̺� �̸� / ���̺� ���� ����

ax3DLimit = zeros(3,2);
ax3DView = zeros(1,2);



% create GUI
h = initGUI();
initAxes();
redraw();

    function h = initGUI()
        scr = get(0,'ScreenSize');
        h.fig = figure('Name','Vessel Graph', 'Resize','off', 'Position', ...
            [((scr(3)-980)/2) ((scr(4)-840)/2) 980 860], 'KeyPressFcn',@onFigKey);
        h.tgroup = uitabgroup('Parent', h.fig);
        h.tab1 = uitab('Parent', h.tgroup, 'Title', '2D');
        h.tab2 = uitab('Parent', h.tgroup, 'Title', '3D');
        
        h.ax = axes('Parent',h.tab1, 'ButtonDownFcn',@onMouseDown, ...
            'XLim',[0 1000], 'YLim',[0 1000], 'XTick',[], 'YTick',[], 'Box','on', ...
            'Units','pixels', 'Position',[160 20 800 800]);
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
        h.vesselsVein = [];
        
        
        
        %3D ���� �ʱ�ȭ
        h.ax3D = axes('Parent',h.tab2, 'ButtonDownFcn',@onMouseDown3D, ...
            'XLim',[0 1000], 'YLim',[0 1000], 'ZLim',[0 1000], ...
            'XTick',[], 'YTick',[], 'ZTick',[], 'Box','on', ... 
            'Units','pixels', 'Position',[160 20 800 800]);
        view(h.ax3D, 3);
        h.rA3D = uicontrol('Style','radiobutton', 'Parent',h.tab2, 'String','Artery', ...
            'Position',[20 800 60 20],'Value',1,'Callback',@onArtery3D);
        h.rV3D = uicontrol('Style','radiobutton', 'Parent',h.tab2, 'String','Vein', ...
            'Position',[90 800 60 20],'Callback',@onVein3D);
        h.list3D = uicontrol('Style','listbox', 'Parent',h.tab2, 'String',{}, ...
            'Min',1, 'Max',1, 'Value',-1, 'FontName', 'Fixedsys', 'FontSize', 10, ...
            'Position',[20 320 130 470], 'Callback',@onSelect3D); % 140
        h.labelText3D = uicontrol('Style','text', 'Parent',h.tab2, 'String',{}, ...
            'String', '�̸�:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 290 40 20]);
        h.labelEdit3D = uicontrol('Style','edit', 'Parent',h.tab2, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 290 60 20], 'KeyPressFcn',@onEditKey3D);
        h.labelSet3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','����', ...
            'Position',[125 290 25 20], 'Callback',@onLabelSet3D, 'Enable', 'off', 'KeyPressFcn',@onSetKey3D);
        
        h.area3D = uipanel('Parent', h.tab2, 'Title', '', 'Units', 'pixels', 'Position', [15 165 140 120]);
        h.open3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','3D �� �ҷ�����', ...
            'Position',[20 260 130 20], 'Callback',@onOpen3D, 'Enable', 'on');
        h.hide3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','3D �� ���߱�/���̱�', ...
            'Position',[20 230 130 20], 'Callback',@onHide3D, 'Enable', 'on');
        h.clearModel3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','3D �� �ʱ�ȭ', ...
            'Position',[20 200 130 20], 'Callback',@onClearModel3D, 'Enable', 'on');
        h.cursor3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','������ Ŀ�� ���', ...
            'Position',[20 170 130 20], 'Callback',@onCursor3D, 'Enable', 'on');
        
        h.areaGraph = uipanel('Parent', h.tab2, 'Title', '', 'Units', 'pixels', 'Position', [15 15 140 150]);
        h.setVertices = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','������ �� > �׷��� ��', ...
            'Position',[20 140 130 20], 'Callback',@onSetVertices, 'Enable', 'on');
        h.deleteGraph3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','�׷��� ��/���� ����', ...
            'Position',[20 110 130 20], 'Callback',@onDeleteGraph3D, 'Enable', 'off');
        h.clearGraph3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','�׷��� �ʱ�ȭ', ...
            'Position',[20 80 130 20], 'Callback',@onClearGraph3D);
        h.importGraph3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','�׷��� ��������', ...
            'Position',[20 50 130 20], 'Callback',@onImportGraph3D);
        h.exportGraph3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','�׷��� ��������', ...
            'Position',[20 20 130 20], 'Callback',@onExportGraph3D);
%        h.boundary = line([18 165; 18 285], [152 165; 152 285], 'Parent',h.tab2, 'HitTest','off', ...
%            'LineWidth',1, 'Color','r');
        
        
        
        h.cmenu3D = uicontextmenu('Parent',h.fig);
        h.menu3D = uimenu(h.cmenu3D, 'Label','Show verticies', 'Checked','off', ...
            'Callback',@onCMenu);
        set(h.list3D, 'UIContextMenu',h.cmenu3D)
        
        % ���� (Atery)
        % ������.. �������� ���ν�Ÿ���� None���� �ؼ� ���� �ȱ׸��� Marker�� ��� ��.
        h.ptsAtery3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
        % ���콺 ������ ��ư���� ���� ���� �� ��� �׵θ� - ���� �׸��� ����
        h.prevAtery3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % ���� ���
        h.edgesAtery3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
        % ������ �󺧸� ǥ�ÿ� ����(���� �ƴ�). V1, V2, ... �������
        h.verticesAtery3D = [];
        % ���� �󺧸� ǥ�ÿ� ����(���� �ƴ�). E1, E2, ... �������
        h.vesselsAtery3D = [];
        
        
        % ���� (Vein)
        % ������.. �������� ���ν�Ÿ���� None���� �ؼ� ���� �ȱ׸��� Marker�� ��� ��.
        h.ptsVein3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % ���콺 ������ ��ư���� ���� ���� �� ��� �׵θ� - ���� �׸��� ����
        h.prevVein3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % ���� ���
        h.edgesVein3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'LineWidth',2, 'Color','b');
        % ������ �󺧸� ǥ�ÿ� ����(���� �ƴ�). V1, V2, ... �������
        h.verticesVein3D = [];
        % ���� �󺧸� ǥ�ÿ� ����(���� �ƴ�). E1, E2, ... �������
        h.vesselsVein3D = [];
    end

    function initAxes(~,~)
        ptsAtery(1,:) = [0 0];
        adjAtery(end+1,end+1) = 0;
        
        onClear();
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
                idx = get(h.list, 'Value');     % ���� ���� ��
                adjAtery(labelAtery{idx,1}, labelAtery{idx,2}) = 0;
                labelAtery(idx,:) = [];
                
                for q = 1:size(labelAtery,1)
                    if isempty(labelAtery{q,4}) || labelAtery{q,4} == 0
                        labelAtery{q,3} = ['A' num2str(q)];
                    end
                end
            end
            
            
            % clear previous selections
            prevIdxAtery = [];
            selectIdxAtery = [];
            
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
                idx = get(h.list, 'Value');     % ���� ���� ��
                adjVein(labelVein{idx,1}, labelVein{idx,2}) = 0;
                labelVein(idx,:) = [];
                
                for q = 1:size(labelVein,1)
                    if isempty(labelVein{q,4}) || labelVein{q,4} == 0
                        labelVein{q,3} = ['V' num2str(q)];
                    end
                end
            end
            
            % clear previous selections
            prevIdxVein = [];
            selectIdxVein = [];
        end
        
        % update GUI
        if strcmp(get(h.labelEdit, 'Enable'), 'on')
            set(h.labelEdit, 'String', '')
            set(h.labelEdit, 'Enable', 'off')
        end

        if strcmp(get(h.labelSet, 'Enable'), 'on')
            set(h.labelSet, 'Enable', 'off')
        end
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
        [fname, fpath] = uigetfile('*.mat','������ MATLAB �׷��� ����(.mat)�� �����ϼ���.');
        if fname ~= 0
            onClear();
            finput = load([fpath '\' fname]);

            ptsAtery = finput.ptsAtery;
            adjAtery = finput.adjAtery;
            labelAtery = finput.labelAtery;

            ptsVein = finput.ptsVein;
            adjVein = finput.adjVein;
            labelVein = finput.labelVein;

            set(h.list, 'Value', 1)
            redraw();
        end
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
        if ishghandle(h.vesselsVein), delete(h.vesselsVein); end
        h.vesselsVein = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
            strcat(labelVein(:,3)), ...  % labelV(:)
            'HitTest','off', 'FontSize', 10, 'Color', 'b', 'FontWeight', 'bold', ...
            'VerticalAlign','bottom', 'HorizontalAlign','left');
        if ~isempty(selectIdxVein)
            set(h.vesselsVein(selectIdxVein), 'Color', 'g')
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


%% 3D ����
    function onOpen3D(~,~)
        [fname, fpath] = uigetfile('*.stl','������ 3D �� ����(.stl)�� �����ϼ���.');
        %stlread���� �ӵ� ������ stlreadF�� ����
        if fname ~= 0
            [v, f, n, c, stltitle] = stlreadF([fpath '\' fname]);
            [v, f]=patchslim(v, f);

            h.p3DH = patch('Faces',f,'Vertices',v,'FaceVertexCData',c, ...
                     'FaceColor',       [0.8 0.8 1.0], ...
                     'EdgeColor',       'none',        ...
                     'AmbientStrength', 0.15,           ...
                     'HitTest','off', ...
                     'Parent', h.ax3D);


            % Add a camera light, and tone down the specular highlighting
            camlight('headlight');
            material('dull');

            % Fix the axes scaling, and set a nice view angle
            axis('image');
            view([20 29]);
            
            set(h.ax3D, 'XTick',[-1000:100:1000], 'YTick',[-1000:100:1000], 'ZTick',[-1000:100:1000])
        end
    end

    function onHide3D(~,~)
        if ~isfield(h, 'p3DH'), return, end
        if isempty(h.p3DH), return, end

        if strcmp(get(h.p3DH, 'Visible'), 'on')
            set(h.ax3D, 'XLimMode', 'manual', 'YLimMode', 'manual', 'ZLimMode', 'manual')
            set(h.p3DH, 'Visible', 'off');
        else
            set(h.p3DH, 'Visible', 'on');
            set(h.ax3D, 'XLimMode', 'auto', 'YLimMode', 'auto', 'ZLimMode', 'auto')
        end
    end

    function onCursor3D(~,~)
        dcm = datacursormode(h.fig);
        set(dcm,'UpdateFcn',@dataText)

        if strcmp(get(dcm, 'enable'), 'on')
            set(dcm, 'enable', 'off');
        else
            set(dcm, 'enable', 'on');
            set(dcm, 'SnapToDataVertex','off');
            set(h.p3DH, 'HitTest','on');
        end
    end

    function onSetTips(~,~)
        set(h.p3DH, 'HitTest','on');
        dcm = datacursormode(h.fig);
        data3 = getCursorInfo(dcm);
        for n = 1:size(ptsAtery3D,1)
            data3(n).Target = h.p3DH;
            data3(n).Position = ptsAtery3D(n,:);
        end
        hh=findall(gca,'Type','hggroup','draggable','on','Marker','square');
        set(hh,'MarkerEdgeColor','r');
    end

    function onSetVertices(~,~)
        dcm = datacursormode(h.fig);
        data3 = getCursorInfo(dcm);
        if isempty(ptsAtery3D)
            ptsAtery3D = zeros(0,3);
            adjAtery3D = sparse([]);
            for n = 1:size(data3,2);
                ptsAtery3D(n,:) = data3(n).Position;
                adjAtery3D(n,n) = 0;
            end
        else
            listN = size(ptsAtery3D,1);
            for n = 1:size(data3,2);
                ptsAtery3D(listN+n,:) = data3(n).Position;
                adjAtery3D(listN+n,listN+n) = 0;
            end
        end
        
        set(h.p3DH, 'HitTest','off');
        redraw3D();
    end

    function redraw3D()
        % ���� �׸��� �ܰ�
        % ����
        p = nan(3*nnz(adjAtery3D),3);
        for q = 1:size(labelAtery3D,1)
            p(1+3*(q-1),:) = ptsAtery3D(labelAtery3D{q,1},:);
            p(2+3*(q-1),:) = ptsAtery3D(labelAtery3D{q,2},:);
        end
        set(h.edgesAtery3D, 'XData',p(:,1), 'YData',p(:,2), 'ZData',p(:,3))
        if ishghandle(h.vesselsAtery3D), delete(h.vesselsAtery3D); end
        h.vesselsAtery3D = text((p(1:3:end,1)+p(2:3:end,1))/2, (p(1:3:end,2)+p(2:3:end,2))/2, (p(1:3:end,3)+p(2:3:end,3))/2, ...
            strcat(labelAtery3D(:,3)), ...  % label(:)
            'HitTest','off', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold', ...
            'VerticalAlign','bottom', 'HorizontalAlign','left');
        if ~isempty(selectIdxAtery3D)
            set(h.vesselsAtery3D(selectIdxAtery3D), 'Color', 'g')
        end

        % �� �׸��� �ܰ�
        % ����
        set(h.ptsAtery3D, 'XData', ptsAtery3D(:,1), 'YData', ptsAtery3D(:,2), 'ZData',ptsAtery3D(:,3))
        set(h.prevAtery3D, 'XData', ptsAtery3D(prevIdxAtery3D,1), 'YData',ptsAtery3D(prevIdxAtery3D,2), 'ZData',ptsAtery3D(prevIdxAtery3D,3))
        
        % ����
%        set(h.ptsVein, 'XData', ptsVein(:,1), 'YData',ptsVein(:,2))
%        set(h.prevVein, 'XData', ptsVein(prevIdxVein,1), 'YData', ptsVein(prevIdxVein,2))

        if vesselState
            if size(labelAtery3D,1) == 1, set(h.list3D, 'Value', 1); end
            % ���� �̸� ���
            set(h.list3D, 'String', strcat(num2str((1:size(labelAtery3D,1))'), ': ', labelAtery3D(:,3)))
        else
%             if size(labelVein,1) == 1, set(h.list, 'Value', 1); end
%             % ���� �̸� ���
%             set(h.list, 'String', strcat(num2str((1:size(labelVein,1))'), ': ', labelVein(:,3)))
        end

        
        % force refresh
        drawnow
    end

    function onClearModel3D(~,~)
        delete(h.p3DH);
    end

    function onDeleteGraph3D(~,~)
        if ~isempty(prevIdxAtery3D)
            idx = prevIdxAtery3D;

            % ������ ���� �ܰ�
            ptsAtery3D(idx,:) = [];

            % ���� ���� �ܰ� (�������� ����� ���� ���)
            adjAtery3D(:,idx) = [];
            adjAtery3D(idx,:) = [];

            rowList = [];
            for q = 1:size(labelAtery3D,1)
                if labelAtery3D{q,1} == idx || labelAtery3D{q,2} == idx
                    rowList = [rowList q];
                end
            end
            labelAtery3D(rowList,:) = [];
            for q = 1:size(labelAtery3D,1)
                if labelAtery3D{q,1} > idx
                    labelAtery3D{q,1} = labelAtery3D{q,1}-1;
                end

                if labelAtery3D{q,2} > idx
                    labelAtery3D{q,2} = labelAtery3D{q,2}-1;
                end

                if isempty(labelAtery3D{q,4}) || labelAtery3D{q,4} == 0
                    labelAtery3D{q,3} = ['A' num2str(q)];
                end
            end

        else
            idx = get(h.list3D, 'Value');     % ���� ���� ��
            adjAtery3D(labelAtery3D{idx,1}, labelAtery3D{idx,2}) = 0;
            labelAtery3D(idx,:) = [];

            for q = 1:size(labelAtery3D,1)
                if isempty(labelAtery3D{q,4}) || labelAtery3D{q,4} == 0
                    labelAtery3D{q,3} = ['A' num2str(q)];
                end
            end
        end
        
        prevIdxAtery3D = [];
        selectIdxAtery3D = [];
        
        if strcmp(get(h.labelEdit3D, 'Enable'), 'on')
            set(h.labelEdit3D, 'String', '')
            set(h.labelEdit3D, 'Enable', 'off')
        end

        if strcmp(get(h.labelSet3D, 'Enable'), 'on')
            set(h.labelSet3D, 'Enable', 'off')
        end

        % update GUI
        set(h.list3D, 'Value',1)
        set(h.deleteGraph3D, 'Enable', 'off')
        redraw3D()
    end

    function onClearGraph3D(~,~)
        % reset everything
        prevIdxAtery3D = [];
        selectIdxAtery3D = [];
        ptsAtery3D = zeros(0,3);
        adjAtery3D = sparse([]);
        labelAtery3D = cell(0,3);      % label ���� ���� ���� �߰�

        prevIdxVein3D = [];
        selectIdxVein3D = [];
        ptsVein3D = zeros(0,3);
        adjVein3D = sparse([]);
        labelVein3D = cell(0,3);      % label ���� ���� ���� �߰�

        % update GUI
        set(h.labelEdit3D, 'String', '')
        set(h.labelEdit3D, 'Enable', 'off')
        set(h.labelSet3D, 'Enable', 'off')
        set(h.deleteGraph3D, 'Enable', 'off')
        set(h.list3D, 'Value', -1)
        redraw3D()
    end

function onMouseDown3D(~,~)
            % get location of mouse click (in data coordinates)
%         if strcmp(get(h.labelEdit3D, 'Enable'), 'on')
%             set(h.labelEdit3D, 'String', '')
%             set(h.labelEdit3D, 'Enable', 'off')
%         end
        
        if vesselState == 1
            % ���� ó�� (Atery)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % left click
                return
            elseif strcmpi(get(h.fig,'SelectionType'), 'alt') || ...
                    strcmpi(get(h.fig,'SelectionType'), 'open')
                % right click (ctrl+left click) / duouble click
                pointCloud = ptsAtery3D';
                point = get(h.ax3D, 'CurrentPoint');
                camPos = get(h.ax3D, 'CameraPosition'); % camera position
                camTgt = get(h.ax3D, 'CameraTarget'); % where the camera is pointing to
%                disp(point)
                
                camDir = camPos - camTgt; % camera direction
                camUpVect = get(gca, 'CameraUpVector'); % camera 'up' vector

                % build an orthonormal frame based on the viewing direction and the 
                % up vector (the "view frame")
                zAxis = camDir/norm(camDir);    
                upAxis = camUpVect/norm(camUpVect); 
                xAxis = cross(upAxis, zAxis);
                yAxis = cross(zAxis, xAxis);

                rot = [xAxis; yAxis; zAxis]; % view rotation 

                % the point cloud represented in the view frame
                rotatedPointCloud = rot * pointCloud; 

                % the clicked point represented in the view frame
                rotatedPointFront = rot * point' ;

                % find the nearest neighbour to the clicked point 
                pointCloudIndex = dsearchn(rotatedPointCloud(1:2,:)', ... 
                rotatedPointFront(1:2));

                if isempty(prevIdxAtery3D)
                    % starting node (requires a second click to finish)
                    prevIdxAtery3D = pointCloudIndex;
                    set(h.deleteGraph3D, 'Enable', 'on')
                else
                    idx = pointCloudIndex;
                    if adjAtery3D(prevIdxAtery3D,idx) ~= 1 && adjAtery3D(idx,prevIdxAtery3D) ~= 1
                        adjAtery3D(prevIdxAtery3D,idx) = 1;
                        m = size(labelAtery3D,1);
                        labelAtery3D{m+1,1} = prevIdxAtery3D;
                        labelAtery3D{m+1,2} = idx;
                        labelAtery3D{m+1,3} = strcat('A', num2str(m+1));
                    else
                        % warndlg('�� ���� �̹� ����Ǿ����ϴ�.','����')
                    end
                    prevIdxAtery3D = [];
                    set(h.deleteGraph3D, 'Enable', 'off')
                end
                
%                fprintf('you clicked on point number %d\n', pointCloudIndex);

%                 % hit test (find node closest to click location: euclidean distnce)
%                 [dst,idx] = min(sum(bsxfun(@minus, ptsAtery, p(1,1:2)).^2,2));
%                 if sqrt(dst) > 8, return; end
%                 set(h.delete, 'Enable', 'on')
%                 
%                 if isempty(prevIdxAtery)
%                     % starting node (requires a second click to finish)
%                     prevIdxAtery = idx;
%                 else
%                     % add the new edge % ���� ���� �ܰ�
%                     if adjAtery(prevIdxAtery,idx) ~= 1 && adjAtery(idx,prevIdxAtery) ~= 1
%                         adjAtery(prevIdxAtery,idx) = 1;
%                         m = size(labelAtery,1);
%                         labelAtery{m+1,1} = prevIdxAtery;
%                         labelAtery{m+1,2} = idx;
%                         labelAtery{m+1,3} = strcat('A', num2str(m+1));
%                     else
%                         % warndlg('�� ���� �̹� ����Ǿ����ϴ�.','����')
%                     end
%                     prevIdxAtery = [];
%                     set(h.delete, 'Enable', 'off')
%                 end
%                 
%                 selectIdxAtery = [];
%                 selectIdxVein = [];
            end
         else
%             % ���� ó�� (Vein)
        end
        
         % update GUI
         redraw3D()
end

    function onExportGraph3D(~,~)
        ax3DLimit = [get(h.ax3D, 'XLim');get(h.ax3D, 'YLim');get(h.ax3D, 'ZLim')];
        ax3DView = get(h.ax3D, 'View');
        fname = datestr(now,'yymmddHHMMSS');
        uisave({'ptsAtery3D', 'adjAtery3D', 'labelAtery3D', 'ptsVein3D', 'adjVein3D', 'labelVein3D', 'ax3DLimit', 'ax3DView'}, ['VG_3D_' fname]);
    end

    function onImportGraph3D(~,~)
        [fname, fpath] = uigetfile('*.mat','������ MATLAB �׷��� ����(.mat)�� �����ϼ���.');
        if fname ~= 0
            onClearGraph3D();
            finput = load([fpath '\' fname]);

            ax3DLimit = finput.ax3DLimit;
            set(h.ax3D, 'XLim', ax3DLimit(1,:));
            set(h.ax3D, 'YLim', ax3DLimit(2,:));
            set(h.ax3D, 'ZLim', ax3DLimit(3,:));

            ax3DView = finput.ax3DView;
            set(h.ax3D, 'View', ax3DView);
            
            ptsAtery3D = finput.ptsAtery3D;
            adjAtery3D = finput.adjAtery3D;
            labelAtery3D = finput.labelAtery3D;

            ptsVein3D = finput.ptsVein3D;
            adjVein3D = finput.adjVein3D;
            labelVein3D = finput.labelVein3D;

            set(h.list3D, 'Value', 1)
            redraw3D();
        end
    end

    function output_txt = dataText(obj,event_obj)
    % Display the position of the data cursor
    % obj          Currently not used (empty)
    % event_obj    Handle to event object
    % output_txt   Data cursor text string (string or cell array of strings).

    % pos = get(event_obj,'Position');
    % output_txt = {['X: ',num2str(pos(1),4)],...
    %     ['Y: ',num2str(pos(2),4)]};
    % 
    % % If there is a Z-coordinate in the position, display it as well
    % if length(pos) > 2
    %     output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
    % end
        output_txt = '';

    end

    function onSelect3D(~,~)
        % update index of currently selected node
        prevIdxAtery3D = [];
        prevIdxVein3D = [];
        
        % ����Ʈ �ڽ��� ����� �� (�ʱ� ����, �����ϴٰ� ��� ������ ����) Value �� ����
        if ~isempty(get(h.list3D, 'String'))
            if vesselState
                selectIdxAtery3D = get(h.list3D, 'Value');
                set(h.labelEdit3D, 'String', labelAtery3D{selectIdxAtery3D, 3})
            else
                selectIdxVein3D = get(h.list3D, 'Value');
                set(h.labelEdit3D, 'String', labelVein3D{selectIdxVein3D, 3})
            end
            
            set(h.labelEdit3D, 'Enable', 'on')
            set(h.deleteGraph3D, 'Enable', 'on')
            set(h.labelSet3D, 'Enable', 'on')
        else
            set(h.list3D, 'Value', -1)
        end
        
        % ���� �� ���� text editor�� Ŀ�� �ڵ� ��ġ
        uicontrol(h.labelEdit3D);
        redraw3D()
    end

    function onLabelSet3D(~,~)
        if strcmp(set(h.labelEdit3D, 'Enable'), 'off'), return; end
        
        if vesselState
            labelAtery3D{selectIdxAtery3D,3} = get(h.labelEdit3D, 'String');
            labelAtery3D{selectIdxAtery3D,4} = 1;
        else
            labelVein3D{selectIdxVein3D,3} = get(h.labelEdit, 'String');
            labelVein3D{selectIdxVein3D,4} = 1;
        end
        
        selectIdxAtery3D = [];
        selectIdxVein3D = [];
        set(h.labelEdit3D, 'String', '')
        set(h.labelEdit3D, 'Enable', 'off')
        set(h.labelSet3D, 'Enable', 'off')
        redraw3D()
    end

    function onEditKey3D(~,~)
        % text edit â���� Enter, ESC Ű���� �Է½� ����
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(13))
            % ��Ŀ���� ���� set ��ư���� �̵�, �׷��� ���� ���� ���� �ݿ� ��
            uicontrol(h.labelSet3D);
            onLabelSet3D();
        elseif isequal(key,char(27))
            selectIdxAtery3D = [];
            selectIdxVein3D = [];
            uicontrol(h.labelSet3D);
%            setCategory();
        end
    end

end
