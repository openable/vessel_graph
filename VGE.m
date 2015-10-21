function VGE
% data
showVertices = true;   % flag to determine whether to show node labels

prevIdxArtery = [];         % keeps track of 1st node clicked in creating edges
selectIdxArtery = [];       % used to highlight node selected in listbox

ptsArtery = zeros(0,2);     % x/y coordinates of vertices
adjArtery = sparse([]);     % sparse adjacency matrix (undirected)    % 선분 연결 정보 기억
labelArtery = cell(0,4);      % 선분 라벨 저장용 변수, 첫번째 점 / 두번째 점 / 레이블 이름 / 레이블 편집 여부

prevIdxVein = [];
selectIdxVein = [];

ptsVein = zeros(0,2);     % x/y coordinates of vertices
adjVein = sparse([]);     % sparse adjacency matrix (undirected)    % 선분 연결 정보 기억
labelVein = cell(0,4);      % 선분 라벨 저장용 변수, 첫번째 점 / 두번째 점 / 레이블 이름 / 레이블 편집 여부

vesselState = 1;        % Artery (1) / Vein (0) state


showVertices3D = false;   % flag to determine whether to show node labels

prevIdxArtery3D = [];         % keeps track of 1st node clicked in creating edges
selectIdxArtery3D = [];       % used to highlight node selected in listbox

ptsArtery3D = zeros(0,3);     % x/y coordinates of vertices
adjArtery3D = sparse([]);     % sparse adjacency matrix (undirected)    % 선분 연결 정보 기억
labelArtery3D = cell(0,5);      % 선분 라벨 저장용 변수, 첫번째 점 / 두번째 점 / 레이블 이름 / 레이블 편집 여부 / 두께

prevIdxVein3D = [];
selectIdxVein3D = [];

ptsVein3D = zeros(0,3);     % x/y coordinates of vertices
adjVein3D = sparse([]);     % sparse adjacency matrix (undirected)    % 선분 연결 정보 기억
labelVein3D = cell(0,5);      % 선분 라벨 저장용 변수, 첫번째 점 / 두번째 점 / 레이블 이름 / 레이블 편집 여부 / 두께

ax3DLimit = zeros(3,2);
ax3DView = zeros(1,2);

vesselState3D = 1;        % Artery (1) / Vein (0) state


% create GUI
h = initGUI();

    function h = initGUI()
        scr = get(0,'ScreenSize');
        h.fig = figure('Name','Vessel Graph', 'Resize','off', 'Position', ...
            [((scr(3)-980)/2) ((scr(4)-840)/2) 980 860], 'KeyPressFcn',@onFigKey, ...
            'numbertitle', 'off');
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
            'String', '이름:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 140 40 20]);
        h.labelEdit = uicontrol('Style','edit', 'Parent',h.tab1, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 140 60 20], 'KeyPressFcn',@onEditKey);
        h.labelSet = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','설정', ...
            'Position',[125 140 25 20], 'Callback',@onLabelSet, 'Enable', 'off', 'KeyPressFcn',@onSetKey);
        h.delete = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','점/선분 삭제', ...
            'Position',[20 110 130 20], 'Callback',@onDelete, 'Enable', 'off');
        h.clear = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','초기화', ...
            'Position',[20 80 130 20], 'Callback',@onClear);
        h.import = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','가져오기', ...
            'Position',[20 50 130 20], 'Callback',@onImport);
        h.export = uicontrol('Style','pushbutton', 'Parent',h.tab1, 'String','내보내기', ...
            'Position',[20 20 130 20], 'Callback',@onExport);
        
        
        
        h.cmenu = uicontextmenu('Parent',h.fig);
        h.menu = uimenu(h.cmenu, 'Label','Show verticies', 'Checked','off', ...
            'Callback',@onCMenu);
        set(h.list, 'UIContextMenu',h.cmenu)
        
        % 동맥 (Artery)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsArtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevArtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 리스트박스 선택된 선분 녹색 강조
        h.selectArtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','g');
        % 선분 목록
        h.edgesArtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.verticesArtery = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vesselsArtery = [];
        
        
        % 정맥 (Vein)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % 마우스 오른쪽 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 리스트박스 선택된 선분 녹색 강조
        h.selectVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','g');
        % 선분 목록
        h.edgesVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','b');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.verticesVein = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vesselsVein = [];
        
        
        
        %3D 내용 초기화
        h.ax3D = axes('Parent',h.tab2, 'ButtonDownFcn',@onMouseDown3D, ...
            'XLim',[0 1000], 'YLim',[0 1000], 'ZLim',[0 1000], ...
            'XTick',[], 'YTick',[], 'ZTick',[], 'Box','on', ... 
            'Units','pixels', 'Position',[160 20 800 800]);
        view(h.ax3D, 3);
        camlight('headlight');
        h.edge3D = uipanel('Parent', h.tab2, 'Title', '', 'Units', 'pixels', 'Position', [15 315 140 510]);
        h.rA3D = uicontrol('Style','radiobutton', 'Parent',h.tab2, 'String','Artery', ...
            'Position',[20 800 60 20],'Value',1,'Callback',@onArtery3D);
        h.rV3D = uicontrol('Style','radiobutton', 'Parent',h.tab2, 'String','Vein', ...
            'Position',[90 800 60 20],'Callback',@onVein3D);
        h.list3D = uicontrol('Style','listbox', 'Parent',h.tab2, 'String',{}, ...
            'Min',1, 'Max',1, 'Value',-1, 'FontName', 'Fixedsys', 'FontSize', 10, ...
            'Position',[20 380 130 410], 'Callback',@onSelect3D); % 140
        
        h.labelText3D = uicontrol('Style','text', 'Parent',h.tab2, 'String',{}, ...
            'String', '이름:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 350 40 20]);
        h.labelEdit3D = uicontrol('Style','edit', 'Parent',h.tab2, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 350 60 20], 'KeyPressFcn',@onLabelEditKey3D);
        h.labelSet3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','설정', ...
            'Position',[125 350 25 20], 'Callback',@onLabelSet3D, 'Enable', 'off', 'KeyPressFcn',@onSetLabelKey3D);
        h.thickLabel3D = uicontrol('Style','text', 'Parent',h.tab2, 'String',{}, ...
            'String', '두께:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 320 40 20]);
        h.thickEdit3D = uicontrol('Style','edit', 'Parent',h.tab2, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 320 60 20], 'KeyPressFcn',@onThickEditKey3D);
        h.thickSet3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','설정', ...
            'Position',[125 320 25 20], 'Callback',@onThickSet3D, 'Enable', 'off', 'KeyPressFcn',@onSetThickKey3D);
        
        h.area3D = uipanel('Parent', h.tab2, 'Title', '', 'Units', 'pixels', 'Position', [15 165 140 150]);
        h.open3DArtery = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','3D 동맥 모델 불러오기', ...
            'Position',[20 290 130 20], 'Callback',@onOpen3DArtery, 'Enable', 'on');
        h.open3DVein = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','3D 정맥 모델 불러오기', ...
            'Position',[20 260 130 20], 'Callback',@onOpen3DVein, 'Enable', 'on');
        h.hide3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','3D 모델 감추기/보이기', ...
            'Position',[20 230 130 20], 'Callback',@onHide3D, 'Enable', 'on');
        h.clearModel3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','3D 모델 초기화', ...
            'Position',[20 200 130 20], 'Callback',@onClearModel3D, 'Enable', 'on');
        h.cursor3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','데이터 커서 모드', ...
            'Position',[20 170 130 20], 'Callback',@onCursor3D, 'Enable', 'on');
        
        h.areaGraph = uipanel('Parent', h.tab2, 'Title', '', 'Units', 'pixels', 'Position', [15 15 140 150]);
        h.setVertices = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','데이터 팁 > 그래프 점', ...
            'Position',[20 140 130 20], 'Callback',@onSetVertices, 'Enable', 'on');
        h.deleteGraph3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','그래프 점/선분 삭제', ...
            'Position',[20 110 130 20], 'Callback',@onDeleteGraph3D, 'Enable', 'off');
        h.clearGraph3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','그래프 초기화', ...
            'Position',[20 80 130 20], 'Callback',@onClearGraph3D);
        h.importGraph3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','그래프 가져오기', ...
            'Position',[20 50 130 20], 'Callback',@onImportGraph3D);
        h.exportGraph3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','그래프 내보내기', ...
            'Position',[20 20 130 20], 'Callback',@onExportGraph3D);
        
        
        
        h.cmenu3D = uicontextmenu('Parent',h.fig);
        h.menu3D = uimenu(h.cmenu3D, 'Label','Show 3D verticies', 'Checked','off', ...
            'Callback',@onCMenu3D);
        set(h.list3D, 'UIContextMenu',h.cmenu3D)
        
        % 동맥 (Artery)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsArtery3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevArtery3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 리스트박스 선택된 선분 녹색 강조
        h.selectArtery3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'LineWidth',2, 'Color','g');
        % 선분 목록
        h.edgesArtery3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.verticesArtery3D = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vesselsArtery3D = [];
        
        
        % 정맥 (Vein)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsVein3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevVein3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 리스트박스 선택된 선분 녹색 강조
        h.selectVein3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'LineWidth',2, 'Color','g');
        % 선분 목록
        h.edgesVein3D = line(NaN, NaN, NaN, 'Parent',h.ax3D, 'HitTest','off', ...
            'LineWidth',2, 'Color','b');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.verticesVein3D = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vesselsVein3D = [];
    end

    function onFigKey(~,~)
        % Figure 창에서 ESC 키보드 입력시 동작
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(27))
            prevIdxArtery = [];
            prevIdxVein = [];
            selectIdxArtery = [];
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
            if ishghandle(h.selectVein), delete(h.selectVein); end
        else    %h.rV.Value == 1
            vesselState = 0;
            prevIdxArtery = [];
            selectIdxArtery = [];
            if ishghandle(h.selectArtery), delete(h.selectArtery); end
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
            set(h.labelSet, 'Enable', 'off')
        end
        
        if ishghandle(h.selectArtery), delete(h.selectArtery); end
        if ishghandle(h.selectVein), delete(h.selectVein); end
        
        p = get(h.ax, 'CurrentPoint');
        
        if vesselState == 1
            % 동맥 처리 (Artery)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                ptsArtery(end+1,:) = p(1,1:2);
                adjArtery(end+1,end+1) = 0;
                
                selectIdxArtery = [];
                selectIdxVein = [];
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+마우스 왼쪽 클릭
                if size(labelArtery,1) < 1, return; end
                labelPts = getLabelPts(ptsArtery, labelArtery);
                [dst,idx] = min(sum(bsxfun(@minus, labelPts, p(1,1:2)).^2,2));
                
                if sqrt(dst) > 20, selectIdxArtery = []; setCategory(); return; end
                onLabelEdit(idx);
            else
                % hit test (find node closest to click location: euclidean distnce)
                [dst,idx] = min(sum(bsxfun(@minus, ptsArtery, p(1,1:2)).^2,2));
                if sqrt(dst) > 8, return; end
                set(h.delete, 'Enable', 'on')
                
                if isempty(prevIdxArtery)
                    % starting node (requires a second click to finish)
                    prevIdxArtery = idx;
                else
                    % add the new edge % 선분 생성 단계
                    if adjArtery(prevIdxArtery,idx) ~= 1 && adjArtery(idx,prevIdxArtery) ~= 1
                        adjArtery(prevIdxArtery,idx) = 1;
                        m = size(labelArtery,1);
                        labelArtery{m+1,1} = prevIdxArtery;
                        labelArtery{m+1,2} = idx;
                        labelArtery{m+1,3} = strcat('A', num2str(m+1));
                    else
                        % warndlg('두 점은 이미 연결되었습니다.','거절')
                    end
                    prevIdxArtery = [];
                    set(h.delete, 'Enable', 'off')
                end
                
                selectIdxArtery = [];
                selectIdxVein = [];
            end
        else
            % 정맥 처리 (Vein)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                ptsVein(end+1,:) = p(1,1:2);
                adjVein(end+1,end+1) = 0;
                
                selectIdxArtery = [];
                selectIdxVein = [];
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+마우스 왼쪽 클릭
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
                    % add the new edge % 선분 생성 단계
                    if adjVein(prevIdxVein,idx) ~= 1 && adjVein(idx,prevIdxVein) ~= 1
                        adjVein(prevIdxVein,idx) = 1;
                        m = size(labelVein,1);
                        labelVein{m+1,1} = prevIdxVein;
                        labelVein{m+1,2} = idx;
                        labelVein{m+1,3} = strcat('V', num2str(m+1));
                    else
                        % warndlg('두 점은 이미 연결되었습니다.','거절')
                    end
                    prevIdxVein = [];
                    set(h.delete, 'Enable', 'off')
                end
                
                selectIdxArtery = [];
                selectIdxVein = [];
            end
        end
        
        % update GUI
        redraw()
    end

    function mat = getLabelPts(pts, label)
        mat = zeros(size(label,1),2);
        for n = 1:size(label,1)
            % x축 좌표는 10씩 일부러 옮겨줌. 라벨 출력이 좌측 정렬로 써져서 보정.
            mat(n,1) = (pts(label{n,1},1) + pts(label{n,2},1))/2 + 8 + 10;
            mat(n,2) = (pts(label{n,1},2) + pts(label{n,2},2))/2 + 8;
        end
    end

    function onDelete(~,~)
        % check that list of nodes is not empty
        if isempty(ptsArtery) && isempty(ptsVein), return; end
        
        % delete selected node
        if vesselState
            if ~isempty(prevIdxArtery)             % 마우스 오른쪽 클릭으로만 Vertex 지움.
                idx = prevIdxArtery;
                
                % 꼭지점 삭제 단계
                ptsArtery(idx,:) = [];
                
                % 선분 삭제 단계 (꼭지점과 연결된 선분 대상)
                adjArtery(:,idx) = [];
                adjArtery(idx,:) = [];
                
                rowList = [];
                for q = 1:size(labelArtery,1)
                    if labelArtery{q,1} == idx || labelArtery{q,2} == idx
                        rowList(end+1) = q;
                    end
                end
                labelArtery(rowList,:) = [];
                for q = 1:size(labelArtery,1)
                    if labelArtery{q,1} > idx
                        labelArtery{q,1} = labelArtery{q,1}-1;
                    end
                    
                    if labelArtery{q,2} > idx
                        labelArtery{q,2} = labelArtery{q,2}-1;
                    end
                    
                    if isempty(labelArtery{q,4}) || labelArtery{q,4} == 0
                        labelArtery{q,3} = ['A' num2str(q)];
                    end
                end
                
            else
                 % 선분 지울 때
                if ishghandle(h.selectArtery), delete(h.selectArtery); end
                
                idx = get(h.list, 'Value');
                adjArtery(labelArtery{idx,1}, labelArtery{idx,2}) = 0;
                labelArtery(idx,:) = [];
                
                for q = 1:size(labelArtery,1)
                    if isempty(labelArtery{q,4}) || labelArtery{q,4} == 0
                        labelArtery{q,3} = ['A' num2str(q)];
                    end
                end
            end
                        
        else
            if ~isempty(prevIdxVein)             % 마우스 오른쪽 클릭으로만 Vertex 지움.
                idx = prevIdxVein;
                
                % 꼭지점 삭제 단계
                ptsVein(idx,:) = [];
                
                % 선분 삭제 단계 (꼭지점과 연결된 선분 대상)
                adjVein(:,idx) = [];
                adjVein(idx,:) = [];
                
                rowList = [];
                for q = 1:size(labelVein,1)
                    if labelVein{q,1} == idx || labelVein{q,2} == idx
                        rowList(end+1) = q;
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
                % 선분 지울 때
                if ishghandle(h.selectVein), delete(h.selectVein); end
                
                idx = get(h.list, 'Value');
                adjVein(labelVein{idx,1}, labelVein{idx,2}) = 0;
                labelVein(idx,:) = [];
                
                for q = 1:size(labelVein,1)
                    if isempty(labelVein{q,4}) || labelVein{q,4} == 0
                        labelVein{q,3} = ['V' num2str(q)];
                    end
                end
            end
        end
        
        prevIdxArtery = [];
        selectIdxArtery = [];
        prevIdxVein = [];
        selectIdxVein = [];
        
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
        prevIdxArtery = [];
        selectIdxArtery = [];
        ptsArtery = zeros(0,2);
        adjArtery = sparse([]);
        labelArtery = cell(0,3);      % label 엣지 정보 제거 추가
        
        prevIdxVein = [];
        selectIdxVein = [];
        ptsVein = zeros(0,2);
        adjVein = sparse([]);
        labelVein = cell(0,3);      % label 엣지 정보 제거 추가
        
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
        uisave({'ptsArtery', 'adjArtery', 'labelArtery', 'ptsVein', 'adjVein', 'labelVein'}, ['VG_' fname]);
    end

    function onImport(~,~)
        [fname, fpath] = uigetfile('*.mat','가져올 MATLAB 그래프 파일(.mat)을 선택하세요.');
        if fname ~= 0
            onClear();
            finput = load([fpath '\' fname]);

            ptsArtery = finput.ptsArtery;
            adjArtery = finput.adjArtery;
            labelArtery = finput.labelArtery;

            ptsVein = finput.ptsVein;
            adjVein = finput.adjVein;
            labelVein = finput.labelVein;

            set(h.list, 'Value', 1)
            redraw();
        end
    end

    function onSelect(~,~)
        % update index of currently selected node
        prevIdxArtery = [];
        prevIdxVein = [];
        
        % 리스트 박스가 비었을 때 (초기 생성, 삭제하다가 모든 아이템 삭제) Value 값 조절
        if ~isempty(get(h.list, 'String'))
            if vesselState
                selectIdxArtery = get(h.list, 'Value');
                set(h.labelEdit, 'String', labelArtery{selectIdxArtery, 3})
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
        
        % 선분 라벨 편집 text editor에 커서 자동 위치
        uicontrol(h.labelEdit);
        redraw()
    end

    function onCMenu(~,~)
        % flip state
        showVertices = ~showVertices;
        redraw()
    end

    function onLabelEdit(idx)
        prevIdxArtery = [];
        prevIdxVein = [];
        
        if vesselState
            selectIdxArtery = idx;
            set(h.labelEdit, 'String', labelArtery{selectIdxArtery, 3})
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
            labelArtery{selectIdxArtery,3} = get(h.labelEdit, 'String');
            labelArtery{selectIdxArtery,4} = 1;
        else
            labelVein{selectIdxVein,3} = get(h.labelEdit, 'String');
            labelVein{selectIdxVein,4} = 1;
        end
        
%         selectIdxArtery = [];
%         selectIdxVein = [];
        set(h.labelEdit, 'String', '')
        set(h.labelEdit, 'Enable', 'off')
        set(h.labelSet, 'Enable', 'off')
        redraw()
    end

    function onEditKey(~,~)
        % text edit 창에서 Enter, ESC 키보드 입력시 동작
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(13))
            % 포커스를 옆에 set 버튼으로 이동, 그래야 현재 편집 정보 반영 됨
            uicontrol(h.labelSet);
            onLabelSet();
        elseif isequal(key,char(27))
            selectIdxArtery = [];
            selectIdxVein = [];
            uicontrol(h.labelSet);
            setCategory();
        end
    end

    function onSetKey(~,~)
        % set 버튼 포커스 후 Enter, ESC 키보드 입력시 동작
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(13))
            onLabelSet();
        elseif isequal(key,char(27))
            selectIdxArtery = [];
            selectIdxVein = [];
            setCategory();
        end
    end

    function redraw()
        % 선분 그리기 단계
        % 동맥
        p = nan(3*nnz(adjArtery),2);
        for q = 1:size(labelArtery,1)
            p(1+3*(q-1),:) = ptsArtery(labelArtery{q,1},:);
            p(2+3*(q-1),:) = ptsArtery(labelArtery{q,2},:);
        end
        set(h.edgesArtery, 'XData',p(:,1), 'YData',p(:,2))
        if ishghandle(h.vesselsArtery), delete(h.vesselsArtery); end
        h.vesselsArtery = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
            strcat(labelArtery(:,3)), ...  % label(:)
            'HitTest','off', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold', ...
            'VerticalAlign','bottom', 'HorizontalAlign','left', 'Parent', h.ax);
        if ~isempty(selectIdxArtery)
            vGroup = [];
            for n = 1:size(labelArtery, 1)
                if strcmp(labelArtery{n,3}, labelArtery{selectIdxArtery,3})
                    vGroup(end+1) = n;
                end
            end
            set(h.vesselsArtery(vGroup), 'Color', 'g')
            if ishghandle(h.selectArtery), delete(h.selectArtery); end
            pgIdx = zeros(1, length(vGroup));
            for n = 1:length(vGroup)
                pgIdx(n*3-2:n*3) = (vGroup(n)-1)*3+1:vGroup(n)*3;
            end
            pg = p(pgIdx,:);
            h.selectArtery = line('XData',pg(:,1), 'YData',pg(:,2), ...
                'Parent',h.ax, 'HitTest','off', 'LineWidth',2, 'Color','g');
        end
        % 정맥
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
            'VerticalAlign','bottom', 'HorizontalAlign','left', 'Parent', h.ax);
        if ~isempty(selectIdxVein)
            vGroup = [];
            for n = 1:size(labelVein, 1)
                if strcmp(labelVein{n,3}, labelVein{selectIdxVein,3})
                    vGroup(end+1) = n;
                end
            end
            set(h.vesselsVein(vGroup), 'Color', 'g')
            if ishghandle(h.selectVein), delete(h.selectVein); end
            pgIdx = zeros(1, length(vGroup));
            for n = 1:length(vGroup)
                pgIdx(n*3-2:n*3) = (vGroup(n)-1)*3+1:vGroup(n)*3;
            end
            pg = p(pgIdx,:);
            h.selectVein = line('XData',pg(:,1), 'YData',pg(:,2), ...
                'Parent',h.ax, 'HitTest','off', 'LineWidth',2, 'Color','g');
        end
        
        % 점 그리기 단계
        % 동맥
        set(h.ptsArtery, 'XData', ptsArtery(:,1), 'YData',ptsArtery(:,2))
        set(h.prevArtery, 'XData', ptsArtery(prevIdxArtery,1), 'YData',ptsArtery(prevIdxArtery,2))
        
        % 정맥
        set(h.ptsVein, 'XData', ptsVein(:,1), 'YData',ptsVein(:,2))
        set(h.prevVein, 'XData', ptsVein(prevIdxVein,1), 'YData', ptsVein(prevIdxVein,2))
        
        % 혈관 이름 (선분) 목록 출력
        if vesselState
            if size(labelArtery,1) == 1, set(h.list, 'Value', 1); end
            % 동맥 이름 출력
            set(h.list, 'String', strcat(num2str((1:size(labelArtery,1))'), ': ', labelArtery(:,3)))
        else
            if size(labelVein,1) == 1, set(h.list, 'Value', 1); end
            % 정맥 이름 출력
            set(h.list, 'String', strcat(num2str((1:size(labelVein,1))'), ': ', labelVein(:,3)))
        end
        
        % 꼭지점 이름 출력
        % 동맥
        if ishghandle(h.verticesArtery), delete(h.verticesArtery); end
        if showVertices
            set(h.menu, 'Checked','on')
            h.verticesArtery = text(ptsArtery(:,1)+2.5, ptsArtery(:,2)+2.5, ...
                strcat('a', num2str((1:size(ptsArtery,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', [0.1,0.1,0.1]*7, 'FontWeight', 'normal', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left', 'Parent', h.ax);
        else
            set(h.menu, 'Checked','off')
        end
        % 정맥
        if ishghandle(h.verticesVein), delete(h.verticesVein); end
        if showVertices
            set(h.menu, 'Checked','on')
            h.verticesVein = text(ptsVein(:,1)+2.5, ptsVein(:,2)+2.5, ...
                strcat('v', num2str((1:size(ptsVein,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', [0.1,0.1,0.1]*7, 'FontWeight', 'normal', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left', 'Parent', h.ax);
        else
            set(h.menu, 'Checked','off')
        end
        
        % force refresh
        drawnow
    end


%% 3D 구현
    function onArtery3D(~,~)
        h.rV3D.Value = ~h.rA3D.Value;
        setCategory3D()
    end

    function onVein3D(~,~)
        h.rA3D.Value = ~h.rV3D.Value;
        setCategory3D()
    end

    function setCategory3D()
        if h.rA3D.Value == 1
            vesselState3D = 1;
            prevIdxVein3D = [];
            selectIdxVein3D = [];
            if ishghandle(h.selectVein3D), delete(h.selectVein3D); end
        else    %h.rV3D.Value == 1
            vesselState3D = 0;
            prevIdxArtery3D = [];
            selectIdxArtery3D = [];
            if ishghandle(h.selectArtery3D), delete(h.selectArtery3D); end
        end
        
        dcm = datacursormode(h.fig);
        if strcmp(get(dcm, 'enable'), 'on')
            dcm.removeAllDataCursors();
            set(dcm, 'enable', 'off');
        end
        
        set(h.labelEdit3D, 'String', '')
        set(h.labelEdit3D, 'Enable', 'off')
        set(h.labelSet3D, 'Enable', 'off')
        set(h.thickEdit3D, 'String', '')
        set(h.thickEdit3D, 'Enable', 'off')
        set(h.thickSet3D, 'Enable', 'off')
        set(h.deleteGraph3D, 'Enable', 'off')
        redraw3D()
    end

    function onOpen3DArtery(~,~)
        if isfield(h, 'p3DHArtery'), if ishghandle(h.p3DHArtery), delete(h.p3DHArtery); end, end
        
        dcm = datacursormode(h.fig);
        if strcmp(get(dcm, 'enable'), 'on')
            dcm.removeAllDataCursors();
            set(dcm, 'enable', 'off');
        end

        [fname, fpath] = uigetfile('*.stl','가져올 3D 모델 파일(.stl)을 선택하세요.');
        %stlread에서 속도 더빠린 stlreadF로 변경
        if fname ~= 0
            [v, f] = stlreadF([fpath '\' fname]);
            [v, f]=patchslim(v, f);
            
            h.p3DHArtery = patch('Faces',f,'Vertices',v, ...
                'FaceColor',       [0.9 0.6 0.9], ...
                'EdgeColor',       'none',        ...
                'FaceAlpha',       0.5,        ...
                'AmbientStrength', 0.15,           ...
                'HitTest','on', ...
                'Parent', h.ax3D);
            
            material('dull');
            axis('image');
            view([20 29]);
            set(h.ax3D, 'XTick',-1000:100:1000, 'YTick',-1000:100:1000, 'ZTick',-1000:100:1000)
        end
    end

    function onOpen3DVein(~,~)
        if isfield(h, 'p3DHVein'), if ishghandle(h.p3DHVein), delete(h.p3DHVein); end, end
    
        dcm = datacursormode(h.fig);
        if strcmp(get(dcm, 'enable'), 'on')
            dcm.removeAllDataCursors();
            set(dcm, 'enable', 'off');
        end
        
        [fname, fpath] = uigetfile('*.stl','가져올 3D 모델 파일(.stl)을 선택하세요.');
        %stlread에서 속도 더빠린 stlreadF로 변경
        if fname ~= 0
            [v, f] = stlreadF([fpath '\' fname]);
            [v, f]=patchslim(v, f);
            
            h.p3DHVein = patch('Faces',f,'Vertices',v, ...
                'FaceColor',       [0.8 0.8 1.0], ...
                'EdgeColor',       'none',        ...
                'FaceAlpha',       0.5,        ...
                'AmbientStrength', 0.15,           ...
                'HitTest','off', ...
                'Parent', h.ax3D);
            
            material('dull');
            axis('image');
            view([20 29]);
            set(h.ax3D, 'XTick',-1000:100:1000, 'YTick',-1000:100:1000, 'ZTick',-1000:100:1000)
        end
    end

    function onHide3D(~,~)
        if ~isfield(h, 'p3DHArtery') || ~isfield(h, 'p3DHVein'), return, end
        if isempty(h.p3DHArtery) || isempty(h.p3DHVein), return, end

        if strcmp(get(h.p3DHArtery, 'Visible'), 'on') || strcmp(get(h.p3DHVein, 'Visible'), 'on')
            set(h.ax3D, 'XLimMode', 'manual', 'YLimMode', 'manual', 'ZLimMode', 'manual')
            set(h.p3DHArtery, 'Visible', 'off');
            set(h.p3DHVein, 'Visible', 'off');
        else
            set(h.p3DHArtery, 'Visible', 'on');
            set(h.p3DHVein, 'Visible', 'on');
            set(h.ax3D, 'XLimMode', 'auto', 'YLimMode', 'auto', 'ZLimMode', 'auto')
        end
    end

    function onCursor3D(~,~)
        if ~isfield(h, 'p3DHArtery') && ~isfield(h, 'p3DHVein'), return, end
        
        dcm = datacursormode(h.fig);
        set(dcm,'UpdateFcn',@dataText)

        if strcmp(get(dcm, 'enable'), 'on')
            set(dcm, 'enable', 'off');
        else
            set(dcm, 'enable', 'on');
            set(dcm, 'SnapToDataVertex','off');
            
            if isfield(h, 'p3DHArtery')
                set(h.p3DHArtery, 'HitTest','off');
                if vesselState3D, set(h.p3DHArtery, 'HitTest','on'); end
            end
            
            if isfield(h, 'p3DHVein')
                set(h.p3DHVein, 'HitTest','off');
                if ~vesselState3D, set(h.p3DHVein, 'HitTest','on'); end
            end
        end
    end

    function onSetVertices(~,~)
        dcm = datacursormode(h.fig);
        data3 = getCursorInfo(dcm);
        
        if vesselState3D
            if isempty(ptsArtery3D)
                ptsArtery3D = zeros(0,3);
                adjArtery3D = sparse([]);
                for n = 1:size(data3,2);
                    ptsArtery3D(n,:) = data3(n).Position;
                    adjArtery3D(n,n) = 0;
                end
            else
                listN = size(ptsArtery3D,1);
                for n = 1:size(data3,2);
                    ptsArtery3D(listN+n,:) = data3(n).Position;
                    adjArtery3D(listN+n,listN+n) = 0;
                end
            end
            
        else
            if isempty(ptsVein3D)
                ptsVein3D = zeros(0,3);
                adjVein3D = sparse([]);
                for n = 1:size(data3,2);
                    ptsVein3D(n,:) = data3(n).Position;
                    adjVein3D(n,n) = 0;
                end
            else
                listN = size(ptsVein3D,1);
                for n = 1:size(data3,2);
                    ptsVein3D(listN+n,:) = data3(n).Position;
                    adjVein3D(listN+n,listN+n) = 0;
                end
            end
        end
        
        if isfield(h, 'p3DHArtery'), set(h.p3DHArtery, 'HitTest','off'); end
        if isfield(h, 'p3DHVein'), set(h.p3DHVein, 'HitTest','off'); end
        redraw3D();
    end

    function redraw3D()
        % 선분 그리기 단계
        % 동맥
        p = nan(3*nnz(adjArtery3D),3);
        for q = 1:size(labelArtery3D,1)
            p(1+3*(q-1),:) = ptsArtery3D(labelArtery3D{q,1},:);
            p(2+3*(q-1),:) = ptsArtery3D(labelArtery3D{q,2},:);
        end
        set(h.edgesArtery3D, 'XData',p(:,1), 'YData',p(:,2), 'ZData',p(:,3))
        if ishghandle(h.vesselsArtery3D), delete(h.vesselsArtery3D); end
        h.vesselsArtery3D = text((p(1:3:end,1)+p(2:3:end,1))/2, (p(1:3:end,2)+p(2:3:end,2))/2, (p(1:3:end,3)+p(2:3:end,3))/2, ...
            strcat(labelArtery3D(:,3)), ...  % label(:)
            'HitTest','off', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold', ...
            'VerticalAlign','bottom', 'HorizontalAlign','left', 'Parent', h.ax3D);
        if ~isempty(selectIdxArtery3D)
            vGroup = [];
            for n = 1:size(labelArtery3D, 1)
                if strcmp(labelArtery3D{n,3}, labelArtery3D{selectIdxArtery3D,3})
                    vGroup(end+1) = n;
                end
            end
            set(h.vesselsArtery3D(vGroup), 'Color', 'g')
            if ishghandle(h.selectArtery3D), delete(h.selectArtery3D); end
            pgIdx = zeros(1, length(vGroup));
            for n = 1:length(vGroup)
                pgIdx(n*3-2:n*3) = (vGroup(n)-1)*3+1:vGroup(n)*3;
            end
            pg = p(pgIdx,:);
            h.selectArtery3D = line('XData',pg(:,1), 'YData',pg(:,2), 'ZData',pg(:,3), ...
                'Parent',h.ax3D, 'HitTest','off', 'LineWidth',2, 'Color','g');
        end
        % 정맥
        p = nan(3*nnz(adjVein3D),3);
        for q = 1:size(labelVein3D,1)
            p(1+3*(q-1),:) = ptsVein3D(labelVein3D{q,1},:);
            p(2+3*(q-1),:) = ptsVein3D(labelVein3D{q,2},:);
        end
        set(h.edgesVein3D, 'XData',p(:,1), 'YData',p(:,2), 'ZData',p(:,3))
        if ishghandle(h.vesselsVein3D), delete(h.vesselsVein3D); end
        h.vesselsVein3D = text((p(1:3:end,1)+p(2:3:end,1))/2, (p(1:3:end,2)+p(2:3:end,2))/2, (p(1:3:end,3)+p(2:3:end,3))/2, ...
            strcat(labelVein3D(:,3)), ...  % label(:)
            'HitTest','off', 'FontSize', 10, 'Color', 'b', 'FontWeight', 'bold', ...
            'VerticalAlign','bottom', 'HorizontalAlign','left', 'Parent', h.ax3D);
        if ~isempty(selectIdxVein3D)
            vGroup = [];
            for n = 1:size(labelVein3D, 1)
                if strcmp(labelVein3D{n,3}, labelVein3D{selectIdxVein3D,3})
                    vGroup(end+1) = n;
                end
            end
            set(h.vesselsVein3D(vGroup), 'Color', 'g')
            if ishghandle(h.selectVein3D), delete(h.selectVein3D); end
            pgIdx = zeros(1, length(vGroup));
            for n = 1:length(vGroup)
                pgIdx(n*3-2:n*3) = (vGroup(n)-1)*3+1:vGroup(n)*3;
            end
            pg = p(pgIdx,:);
            h.selectVein3D = line('XData',pg(:,1), 'YData',pg(:,2), 'ZData',pg(:,3), ...
                'Parent',h.ax3D, 'HitTest','off', 'LineWidth',2, 'Color','g');
        end
        

        % 점 그리기 단계
        % 동맥
        set(h.ptsArtery3D, 'XData', ptsArtery3D(:,1), 'YData', ptsArtery3D(:,2), 'ZData',ptsArtery3D(:,3))
        set(h.prevArtery3D, 'XData', ptsArtery3D(prevIdxArtery3D,1), 'YData',ptsArtery3D(prevIdxArtery3D,2), 'ZData',ptsArtery3D(prevIdxArtery3D,3))
        
        % 정맥
        set(h.ptsVein3D, 'XData', ptsVein3D(:,1), 'YData', ptsVein3D(:,2), 'ZData',ptsVein3D(:,3))
        set(h.prevVein3D, 'XData', ptsVein3D(prevIdxVein3D,1), 'YData',ptsVein3D(prevIdxVein3D,2), 'ZData',ptsVein3D(prevIdxVein3D,3))

        if vesselState3D
            if size(labelArtery3D,1) == 1, set(h.list3D, 'Value', 1); end
            % 동맥 이름 출력
            set(h.list3D, 'String', strcat(num2str((1:size(labelArtery3D,1))'), ': ', labelArtery3D(:,3)))
        else
            if size(labelVein3D,1) == 1, set(h.list3D, 'Value', 1); end
            % 정맥 이름 출력
            set(h.list3D, 'String', strcat(num2str((1:size(labelVein3D,1))'), ': ', labelVein3D(:,3)))

        end

        % 꼭지점 이름 출력
        % 동맥
        if ishghandle(h.verticesArtery3D), delete(h.verticesArtery3D); end
        if showVertices3D
            set(h.menu3D, 'Checked','on')
            h.verticesArtery3D = text(ptsArtery3D(:,1)+2.5, ptsArtery3D(:,2)+2.5,  ptsArtery3D(:,3)+2.5,...
                strcat('a', num2str((1:size(ptsArtery3D,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', [0.1,0.1,0.1]*7, 'FontWeight', 'normal', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left', 'Parent', h.ax3D);
        else
            set(h.menu3D, 'Checked','off')
        end
        % 정맥
        if ishghandle(h.verticesVein3D), delete(h.verticesVein3D); end
        if showVertices3D
            set(h.menu3D, 'Checked','on')
            h.verticesVein3D = text(ptsVein3D(:,1)+2.5, ptsVein3D(:,2)+2.5,  ptsVein3D(:,3)+2.5,...
                strcat('v', num2str((1:size(ptsVein3D,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', [0.1,0.1,0.1]*7, 'FontWeight', 'normal', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left', 'Parent', h.ax3D);
        else
            set(h.menu3D, 'Checked','off')
        end
        
        % force refresh
        drawnow
    end

    function onClearModel3D(~,~)
        if ishghandle(h.p3DHArtery), delete(h.p3DHArtery); end
        if ishghandle(h.p3DHVein), delete(h.p3DHVein); end
    end

    function onDeleteGraph3D(~,~)
        % check that list of nodes is not empty
        if isempty(ptsArtery3D) && isempty(ptsVein3D), return; end
        
        % delete selected node
        if vesselState3D
            if ~isempty(prevIdxArtery3D)
                idx = prevIdxArtery3D;

                % 꼭지점 삭제 단계
                ptsArtery3D(idx,:) = [];

                % 선분 삭제 단계 (꼭지점과 연결된 선분 대상)
                adjArtery3D(:,idx) = [];
                adjArtery3D(idx,:) = [];

                rowList = [];
                for q = 1:size(labelArtery3D,1)
                    if labelArtery3D{q,1} == idx || labelArtery3D{q,2} == idx
                        rowList(end+1) = q;
                    end
                end
                labelArtery3D(rowList,:) = [];
                for q = 1:size(labelArtery3D,1)
                    if labelArtery3D{q,1} > idx
                        labelArtery3D{q,1} = labelArtery3D{q,1}-1;
                    end

                    if labelArtery3D{q,2} > idx
                        labelArtery3D{q,2} = labelArtery3D{q,2}-1;
                    end

                    if isempty(labelArtery3D{q,4}) || labelArtery3D{q,4} == 0
                        labelArtery3D{q,3} = ['A' num2str(q)];
                    end
                end

            else
                 % 선분 지울 때
                if ishghandle(h.selectArtery3D), delete(h.selectArtery3D); end
                
                idx = get(h.list3D, 'Value');    
                adjArtery3D(labelArtery3D{idx,1}, labelArtery3D{idx,2}) = 0;
                labelArtery3D(idx,:) = [];

                for q = 1:size(labelArtery3D,1)
                    if isempty(labelArtery3D{q,4}) || labelArtery3D{q,4} == 0
                        labelArtery3D{q,3} = ['A' num2str(q)];
                    end
                end
            end
            
        else
            if ~isempty(prevIdxVein3D)
                idx = prevIdxVein3D;

                % 꼭지점 삭제 단계
                ptsVein3D(idx,:) = [];

                % 선분 삭제 단계 (꼭지점과 연결된 선분 대상)
                adjVein3D(:,idx) = [];
                adjVein3D(idx,:) = [];

                rowList = [];
                for q = 1:size(labelVein3D,1)
                    if labelVein3D{q,1} == idx || labelVein3D{q,2} == idx
                        rowList(end+1) = q;
                    end
                end
                labelVein3D(rowList,:) = [];
                for q = 1:size(labelVein3D,1)
                    if labelVein3D{q,1} > idx
                        labelVein3D{q,1} = labelVein3D{q,1}-1;
                    end

                    if labelVein3D{q,2} > idx
                        labelVein3D{q,2} = labelVein3D{q,2}-1;
                    end

                    if isempty(labelVein3D{q,4}) || labelVein3D{q,4} == 0
                        labelVein3D{q,3} = ['V' num2str(q)];
                    end
                end

            else
                % 선분 지울 때
                if ishghandle(h.selectVein3D), delete(h.selectVein3D); end
                
                idx = get(h.list3D, 'Value');
                adjVein3D(labelVein3D{idx,1}, labelVein3D{idx,2}) = 0;
                labelVein3D(idx,:) = [];

                for q = 1:size(labelVein3D,1)
                    if isempty(labelVein3D{q,4}) || labelVein3D{q,4} == 0
                        labelVein3D{q,3} = ['V' num2str(q)];
                    end
                end
            end
        end
        
        prevIdxArtery3D = [];
        selectIdxArtery3D = [];
        prevIdxVein3D = [];
        selectIdxVein3D = [];
        
        if strcmp(get(h.labelEdit3D, 'Enable'), 'on')
            set(h.labelEdit3D, 'String', '')
            set(h.labelEdit3D, 'Enable', 'off')
            set(h.thickEdit3D, 'String', '')
            set(h.thickEdit3D, 'Enable', 'off')
        end

        if strcmp(get(h.labelSet3D, 'Enable'), 'on')
            set(h.labelSet3D, 'Enable', 'off')
            set(h.thickSet3D, 'Enable', 'off')
        end

        % update GUI
        set(h.list3D, 'Value',1)
        set(h.deleteGraph3D, 'Enable', 'off')
        redraw3D()
    end

    function onClearGraph3D(~,~)
        % reset everything
        prevIdxArtery3D = [];
        selectIdxArtery3D = [];
        ptsArtery3D = zeros(0,3);
        adjArtery3D = sparse([]);
        labelArtery3D = cell(0,3);      % label 엣지 정보 제거 추가

        prevIdxVein3D = [];
        selectIdxVein3D = [];
        ptsVein3D = zeros(0,3);
        adjVein3D = sparse([]);
        labelVein3D = cell(0,3);      % label 엣지 정보 제거 추가

        % update GUI
        set(h.labelEdit3D, 'String', '')
        set(h.labelEdit3D, 'Enable', 'off')
        set(h.labelSet3D, 'Enable', 'off')
        set(h.thickEdit3D, 'String', '')
        set(h.thickEdit3D, 'Enable', 'off')
        set(h.thickSet3D, 'Enable', 'off')
        set(h.deleteGraph3D, 'Enable', 'off')
        set(h.list3D, 'Value', -1)
        redraw3D()
    end

    function onMouseDown3D(~,~)
        % get location of mouse click (in data coordinates)
        if strcmp(get(h.labelEdit3D, 'Enable'), 'on')
            set(h.labelEdit3D, 'String', '')
            set(h.labelEdit3D, 'Enable', 'off')
            set(h.labelSet3D, 'Enable', 'off')
            set(h.thickEdit3D, 'String', '')
            set(h.thickEdit3D, 'Enable', 'off')
            set(h.thickSet3D, 'Enable', 'off')
        end
        
        if ishghandle(h.selectArtery3D), delete(h.selectArtery3D); end
        if ishghandle(h.selectVein3D), delete(h.selectVein3D); end
        
        if vesselState3D == 1
            % 동맥 처리 (Artery)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % left click
            elseif strcmpi(get(h.fig,'SelectionType'), 'alt') || ...
                    strcmpi(get(h.fig,'SelectionType'), 'open')
                % right click (ctrl+left click) / duouble click
                pointCloud = ptsArtery3D';
                point = get(h.ax3D, 'CurrentPoint');
                camPos = get(h.ax3D, 'CameraPosition'); % camera position
                camTgt = get(h.ax3D, 'CameraTarget'); % where the camera is pointing to
                
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
                
                if isempty(prevIdxArtery3D)
                    % starting node (requires a second click to finish)
                    prevIdxArtery3D = pointCloudIndex;
                    set(h.deleteGraph3D, 'Enable', 'on')
                else
                    idx = pointCloudIndex;
                    if adjArtery3D(prevIdxArtery3D,idx) ~= 1 && adjArtery3D(idx,prevIdxArtery3D) ~= 1
                        adjArtery3D(prevIdxArtery3D,idx) = 1;
                        m = size(labelArtery3D,1);
                        labelArtery3D{m+1,1} = prevIdxArtery3D;
                        labelArtery3D{m+1,2} = idx;
                        labelArtery3D{m+1,3} = strcat('A', num2str(m+1));
                        labelArtery3D{m+1,5} = 1;
                    else
                        % warndlg('두 점은 이미 연결되었습니다.','거절')
                    end
                    prevIdxArtery3D = [];
                    set(h.deleteGraph3D, 'Enable', 'off')
                end
            end
            
        else
            % 정맥 처리 (Vein)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % left click
            elseif strcmpi(get(h.fig,'SelectionType'), 'alt') || ...
                    strcmpi(get(h.fig,'SelectionType'), 'open')
                % right click (ctrl+left click) / duouble click
                pointCloud = ptsVein3D';
                point = get(h.ax3D, 'CurrentPoint');
                camPos = get(h.ax3D, 'CameraPosition'); % camera position
                camTgt = get(h.ax3D, 'CameraTarget'); % where the camera is pointing to
                
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
                
                if isempty(prevIdxVein3D)
                    % starting node (requires a second click to finish)
                    prevIdxVein3D = pointCloudIndex;
                    set(h.deleteGraph3D, 'Enable', 'on')
                else
                    idx = pointCloudIndex;
                    if adjVein3D(prevIdxVein3D,idx) ~= 1 && adjVein3D(idx,prevIdxVein3D) ~= 1
                        adjVein3D(prevIdxVein3D,idx) = 1;
                        m = size(labelVein3D,1);
                        labelVein3D{m+1,1} = prevIdxVein3D;
                        labelVein3D{m+1,2} = idx;
                        labelVein3D{m+1,3} = strcat('V', num2str(m+1));
                        labelVein3D{m+1,5} = 1;
                    else
                        % warndlg('두 점은 이미 연결되었습니다.','거절')
                    end
                    prevIdxVein3D = [];
                    set(h.deleteGraph3D, 'Enable', 'off')
                end
            end
        end
        
        selectIdxArtery3D = [];
        selectIdxVein3D = [];

        % update GUI
        redraw3D()
    end

    function onExportGraph3D(~,~)
        ax3DLimit = [get(h.ax3D, 'XLim');get(h.ax3D, 'YLim');get(h.ax3D, 'ZLim')];
        ax3DView = get(h.ax3D, 'View');
        fname = datestr(now,'yymmddHHMMSS');
        uisave({'ptsArtery3D', 'adjArtery3D', 'labelArtery3D', 'ptsVein3D', 'adjVein3D', 'labelVein3D', 'ax3DLimit', 'ax3DView'}, ['VG_3D_' fname]);
    end

    function onImportGraph3D(~,~)
        [fname, fpath] = uigetfile('*.mat','가져올 MATLAB 그래프 파일(.mat)을 선택하세요.');
        if fname ~= 0
            onClearGraph3D();
            finput = load([fpath '\' fname]);

            ax3DLimit = finput.ax3DLimit;
            set(h.ax3D, 'XLim', ax3DLimit(1,:));
            set(h.ax3D, 'YLim', ax3DLimit(2,:));
            set(h.ax3D, 'ZLim', ax3DLimit(3,:));

            ax3DView = finput.ax3DView;
            set(h.ax3D, 'View', ax3DView);
            
            ptsArtery3D = finput.ptsArtery3D;
            adjArtery3D = finput.adjArtery3D;
            labelArtery3D = finput.labelArtery3D;

            ptsVein3D = finput.ptsVein3D;
            adjVein3D = finput.adjVein3D;
            labelVein3D = finput.labelVein3D;

            set(h.list3D, 'Value', 1)
            redraw3D();
        end
    end

    function output_txt = dataText(~,~)
        output_txt = '';
    end

    function onSelect3D(~,~)
        % update index of currently selected node
        prevIdxArtery3D = [];
        prevIdxVein3D = [];
        
        % 리스트 박스가 비었을 때 (초기 생성, 삭제하다가 모든 아이템 삭제) Value 값 조절
        if ~isempty(get(h.list3D, 'String'))
            if vesselState3D
                selectIdxArtery3D = get(h.list3D, 'Value');
                set(h.labelEdit3D, 'String', labelArtery3D{selectIdxArtery3D, 3})
                set(h.thickEdit3D, 'String', labelArtery3D{selectIdxArtery3D, 5})
            else
                selectIdxVein3D = get(h.list3D, 'Value');
                set(h.labelEdit3D, 'String', labelVein3D{selectIdxVein3D, 3})
                set(h.thickEdit3D, 'String', labelVein3D{selectIdxVein3D, 5})
            end
            
            set(h.labelEdit3D, 'Enable', 'on')
            set(h.deleteGraph3D, 'Enable', 'on')
            set(h.labelSet3D, 'Enable', 'on')
            
            set(h.thickLabel3D, 'Enable', 'on')
            set(h.thickEdit3D, 'Enable', 'on')
            set(h.thickSet3D, 'Enable', 'on')
        else
            set(h.list3D, 'Value', -1)
        end
        
        % 선분 라벨 편집 text editor에 커서 자동 위치
        uicontrol(h.labelEdit3D);
        redraw3D()
    end

    function onCMenu3D(~,~)
        % flip state
        showVertices3D = ~showVertices3D;
        redraw3D()
    end

    function onLabelSet3D(~,~)
        if strcmp(set(h.labelEdit3D, 'Enable'), 'off'), return; end
        
        if vesselState3D
            labelArtery3D{selectIdxArtery3D,3} = get(h.labelEdit3D, 'String');
            labelArtery3D{selectIdxArtery3D,4} = 1;
        else
            labelVein3D{selectIdxVein3D,3} = get(h.labelEdit3D, 'String');
            labelVein3D{selectIdxVein3D,4} = 1;
        end
        
%        selectIdxArtery3D = [];
%        selectIdxVein3D = [];
        set(h.labelEdit3D, 'String', '')
        set(h.labelEdit3D, 'Enable', 'off')
        set(h.labelSet3D, 'Enable', 'off')
        set(h.thickEdit3D, 'String', '')
        set(h.thickEdit3D, 'Enable', 'off')
        set(h.thickSet3D, 'Enable', 'off')
        redraw3D()
    end

    function onLabelEditKey3D(~,~)
        % text edit 창에서 Enter, ESC 키보드 입력시 동작
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(13))
            % 포커스를 옆에 set 버튼으로 이동, 그래야 현재 편집 정보 반영 됨
            uicontrol(h.labelSet3D);
            onLabelSet3D();
        elseif isequal(key,char(27))
            selectIdxArtery3D = [];
            selectIdxVein3D = [];
            uicontrol(h.labelSet3D);
            setCategory3D();
        end
    end

    function onSetLabelKey3D(~,~)
        % set 버튼 포커스 후 Enter, ESC 키보드 입력시 동작
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(13))
            % 포커스를 옆에 set 버튼으로 이동, 그래야 현재 편집 정보 반영 됨
            onLabelSet3D();
        elseif isequal(key,char(27))
            selectIdxArtery3D = [];
            selectIdxVein3D = [];
            setCategory3D();
        end
    end

    function onThickSet3D(~,~)
        if strcmp(set(h.thickEdit3D, 'Enable'), 'off'), return, end
        thickness = get(h.thickEdit3D, 'String');
        if isnan(str2double(thickness)), return, end
        
        if vesselState3D
            labelArtery3D{selectIdxArtery3D,5} = thickness;
        else
            labelVein3D{selectIdxVein3D,5} = thickness;
        end
        
        set(h.labelEdit3D, 'String', '')
        set(h.labelEdit3D, 'Enable', 'off')
        set(h.labelSet3D, 'Enable', 'off')
        set(h.thickEdit3D, 'String', '')
        set(h.thickEdit3D, 'Enable', 'off')
        set(h.thickSet3D, 'Enable', 'off')
        redraw3D()
    end

    function onThickEditKey3D(~,~)
        % text edit 창에서 Enter, ESC 키보드 입력시 동작
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(13))
            % 포커스를 옆에 set 버튼으로 이동, 그래야 현재 편집 정보 반영 됨
            uicontrol(h.thickSet3D);
            onThickSet3D();
        elseif isequal(key,char(27))
            selectIdxArtery3D = [];
            selectIdxVein3D = [];
            uicontrol(h.thickSet3D);
            setCategory3D();
        end
    end

    function onSetThickKey3D(~,~)
        % set 버튼 포커스 후 Enter, ESC 키보드 입력시 동작
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(13))
            onThickSet3D();
        elseif isequal(key,char(27))
            selectIdxArtery = [];
            selectIdxVein = [];
            setCategory3D();
        end
    end
end
