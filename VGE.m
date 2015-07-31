function VGE
% data
showVertices = true;   % flag to determine whether to show node labels

prevIdxAtery = [];         % keeps track of 1st node clicked in creating edges
selectIdxAtery = [];       % used to highlight node selected in listbox

ptsAtery = zeros(0,2);     % x/y coordinates of vertices
adjAtery = sparse([]);     % sparse adjacency matrix (undirected)    % 선분 연결 정보 기억
labelAtery = cell(0,4);      % 선분 라벨 저장용 변수, 첫번째 점 / 두번째 점 / 레이블 이름 / 레이블 편집 여부

prevIdxVein = [];
selectIdxVein = [];

ptsVein = zeros(0,2);     % x/y coordinates of vertices
adjVein = sparse([]);     % sparse adjacency matrix (undirected)    % 선분 연결 정보 기억
labelVein = cell(0,4);      % 선분 라벨 저장용 변수, 첫번째 점 / 두번째 점 / 레이블 이름 / 레이블 편집 여부

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
        
        % 동맥 (Atery)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsAtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevAtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 선분 목록
        h.edgesAtery = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.verticesAtery = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vesselsAtery = [];
        
        
        % 정맥 (Vein)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 선분 목록
        h.edgesVein = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','b');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.verticesVein = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vesselsVein = [];
        
        
        
        
        
        
        %3D 내용 초기화
        h.ax3D = axes('Parent',h.tab2, 'ButtonDownFcn',@onMouseDown3D, ...
            'XTick',[], 'YTick',[], 'ZTick',[], 'Box','on', ...
            'Units','normalized', 'Position',[0.165 0.025 0.82 0.96]);
        h.rA3D = uicontrol('Style','radiobutton', 'Parent',h.tab2, 'String','Artery', ...
            'Position',[20 800 60 20],'Value',1,'Callback',@onArtery3D);
        h.rV3D = uicontrol('Style','radiobutton', 'Parent',h.tab2, 'String','Vein', ...
            'Position',[90 800 60 20],'Callback',@onVein3D);
        h.list3D = uicontrol('Style','listbox', 'Parent',h.tab2, 'String',{}, ...
            'Min',1, 'Max',1, 'Value',-1, 'FontName', 'Fixedsys', 'FontSize', 10, ...
            'Position',[20 200 130 590], 'Callback',@onSelect3D); % 140
        h.labelText3D = uicontrol('Style','text', 'Parent',h.tab2, 'String',{}, ...
            'String', '이름:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 170 40 20]);
        h.labelEdit3D = uicontrol('Style','edit', 'Parent',h.tab2, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 170 60 20], 'KeyPressFcn',@onEditKey3D);
        h.labelSet3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','설정', ...
            'Position',[125 170 25 20], 'Callback',@onLabelSet3D, 'Enable', 'off', 'KeyPressFcn',@onSetKey3D);
        h.open3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','3D 모델 불러오기', ...
            'Position',[20 140 130 20], 'Callback',@onOpen3D, 'Enable', 'on');
        h.delete3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','점/선분 삭제', ...
            'Position',[20 110 130 20], 'Callback',@onDelete3D, 'Enable', 'off');
        h.clear3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','초기화', ...
            'Position',[20 80 130 20], 'Callback',@onClear3D);
        h.import3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','가져오기', ...
            'Position',[20 50 130 20], 'Callback',@onImport3D);
        h.export3D = uicontrol('Style','pushbutton', 'Parent',h.tab2, 'String','내보내기', ...
            'Position',[20 20 130 20], 'Callback',@onExport3D);
        
        
        
        h.cmenu3D = uicontextmenu('Parent',h.fig);
        h.menu3D = uimenu(h.cmenu3D, 'Label','Show verticies', 'Checked','off', ...
            'Callback',@onCMenu);
        set(h.list3D, 'UIContextMenu',h.cmenu3D)
        
        % 동맥 (Atery)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsAtery3D = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevAtery3D = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 선분 목록
        h.edgesAtery3D = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.verticesAtery3D = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vesselsAtery3D = [];
        
        
        % 정맥 (Vein)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsVein3D = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevVein3D = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 선분 목록
        h.edgesVein3D = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
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
            % 동맥 처리 (Atery)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                ptsAtery(end+1,:) = p(1,1:2);
                adjAtery(end+1,end+1) = 0;
                
                selectIdxAtery = [];
                selectIdxVein = [];
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+마우스 왼쪽 클릭
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
                    % add the new edge % 선분 생성 단계
                    if adjAtery(prevIdxAtery,idx) ~= 1 && adjAtery(idx,prevIdxAtery) ~= 1
                        adjAtery(prevIdxAtery,idx) = 1;
                        m = size(labelAtery,1);
                        labelAtery{m+1,1} = prevIdxAtery;
                        labelAtery{m+1,2} = idx;
                        labelAtery{m+1,3} = strcat('A', num2str(m+1));
                    else
                        % warndlg('두 점은 이미 연결되었습니다.','거절')
                    end
                    prevIdxAtery = [];
                    set(h.delete, 'Enable', 'off')
                end
                
                selectIdxAtery = [];
                selectIdxVein = [];
            end
        else
            % 정맥 처리 (Vein)
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                ptsVein(end+1,:) = p(1,1:2);
                adjVein(end+1,end+1) = 0;
                
                selectIdxAtery = [];
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
            % x축 좌표는 10씩 일부러 옮겨줌. 라벨 출력이 좌측 정렬로 써져서 보정.
            mat(n,1) = (pts(label{n,1},1) + pts(label{n,2},1))/2 + 8 + 10;
            mat(n,2) = (pts(label{n,1},2) + pts(label{n,2},2))/2 + 8;
        end
    end

    function onDelete(~,~)
        % check that list of nodes is not empty
        if isempty(ptsAtery) && isempty(ptsVein), return; end
        
        % delete selected node
        if vesselState
            if ~isempty(prevIdxAtery)             % 마우스 오른쪽 클릭으로만 Vertex 지움.
                idx = prevIdxAtery;
                %            prevIdx = [];              %밑에서 초기화 하니 불필요 예상됨
                
                % 꼭지점 삭제 단계
                ptsAtery(idx,:) = [];
                
                % 선분 삭제 단계 (꼭지점과 연결된 선분 대상)
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
                idx = get(h.list, 'Value');     % 선분만 지울 때 (꼭지점은 그대로)
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
                idx = get(h.list, 'Value');     % 선분만 지울 때 (꼭지점은 그대로)
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
        labelAtery = cell(0,3);      % label 엣지 정보 제거 추가
        
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
        uisave({'ptsAtery', 'adjAtery', 'labelAtery', 'ptsVein', 'adjVein', 'labelVein'}, ['VG_' fname]);
    end

    function onImport(~,~)
        FileName = uigetfile('*.mat','가져올 MATLAB 그래프 파일(.mat)을 선택하세요.');
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
        
        % 리스트 박스가 비었을 때 (초기 생성, 삭제하다가 모든 아이템 삭제) Value 값 조절
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
        % text edit 창에서 Enter, ESC 키보드 입력시 동작
        key = get(h.fig,'CurrentCharacter');
        
        if isequal(key,char(13))
            % 포커스를 옆에 set 버튼으로 이동, 그래야 현재 편집 정보 반영 됨
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
        % set 버튼 포커스 후 Enter, ESC 키보드 입력시 동작
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
        % 선분 그리기 단계
        % 동맥
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
            'VerticalAlign','bottom', 'HorizontalAlign','left');
        if ~isempty(selectIdxVein)
            set(h.vesselsVein(selectIdxVein), 'Color', 'g')
        end
        
        % 점 그리기 단계
        % 동맥
        set(h.ptsAtery, 'XData', ptsAtery(:,1), 'YData',ptsAtery(:,2))
        set(h.prevAtery, 'XData', ptsAtery(prevIdxAtery,1), 'YData',ptsAtery(prevIdxAtery,2))
        
        % 정맥
        set(h.ptsVein, 'XData', ptsVein(:,1), 'YData',ptsVein(:,2))
        set(h.prevVein, 'XData', ptsVein(prevIdxVein,1), 'YData', ptsVein(prevIdxVein,2))
        
        % 혈관 이름 (선분) 목록 출력
        if vesselState
            if size(labelAtery,1) == 1, set(h.list, 'Value', 1); end
            % 동맥 이름 출력
            set(h.list, 'String', strcat(num2str((1:size(labelAtery,1))'), ': ', labelAtery(:,3)))
        else
            if size(labelVein,1) == 1, set(h.list, 'Value', 1); end
            % 정맥 이름 출력
            set(h.list, 'String', strcat(num2str((1:size(labelVein,1))'), ': ', labelVein(:,3)))
        end
        
        % 꼭지점 이름 출력
        % 동맥
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
        % 정맥
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



    function onOpen3D(~,~)
        filename = uigetfile('*.stl','가져올 3D 모델 파일(.stl)을 선택하세요.');
        
        [F, V, C] = rndread(filename);
        p = patch('faces', F, 'vertices' ,V);
        %set(p, 'facec', 'b');              % Set the face color (force it)
        set(p, 'facec', 'flat');            % Set the face color flat
        set(p, 'FaceVertexCData', C);       % Set the color (from file)
        %set(p, 'facealpha',.4)             % Use for transparency
        set(p, 'EdgeColor','none');         % Set the edge color
        %set(p, 'EdgeColor',[1 0 0 ]);      % Use to see triangles, if needed.
        set(h.ax3D.XLabel, 'String', 'X');
        set(h.ax3D.YLabel, 'String', 'Y');
        set(h.ax3D.ZLabel, 'String', 'Z');
        
        light                               % add a default light
        daspect([1 1 1])                    % Setting the aspect ratio
        view(3)                             % Isometric view
        %xlabel('X'),ylabel('Y'),zlabel('Z')
        drawnow                             %, axis manual
        %
        %disp(['CAD file ' filename ' data is read, will now show object rotating'])

    end


    function Rx = rx(THETA)
        % ROTATION ABOUT THE X-axis
        %
        % Rx = rx(THETA)
        %
        % This is the homogeneous transformation for
        % rotation about the X-axis.
        %
        %	    NOTE:  The angle THETA must be in DEGREES.
        %
        THETA = THETA*pi/180;  % Note: THETA in radians.
        c = cos(THETA);
        s = sin(THETA);
        Rx = [1 0 0 0; 0 c -s 0; 0 s c 0; 0 0 0 1];
    end


    function Ry = ry(THETA)
        % ROTATION ABOUT THE Y-axis
        %
        % Ry = ry(THETA)
        %
        % This is the homogeneous transformation for
        % rotation about the Y-axis.
        %
        %		NOTE: The angel THETA must be in DEGREES.
        %
        THETA = THETA*pi/180;  %Note: THETA is in radians.
        c = cos(THETA);
        s = sin(THETA);
        Ry = [c 0 s 0; 0 1 0 0; -s 0 c 0; 0 0 0 1];
    end

    function Rz = rz(THETA)
        % ROTATION ABOUT THE Z-axis
        %
        % Rz = rz(THETA)
        %
        % This is the homogeneous transformation for
        % rotation about the Z-axis.
        %
        %		NOTE:  The angle THETA must be in DEGREES.
        %
        THETA = THETA*pi/180;  %Note: THETA is in radians.
        c = cos(THETA);
        s = sin(THETA);
        Rz = [c -s 0 0; s c 0 0; 0 0 1 0; 0 0 0 1];
    end

    function T = tl(x,y,z)
        % TRANSLATION ALONG THE X, Y, AND Z AXES
        %
        % T = tl(x,y,z)
        %
        % This is the homogeneous transformation for
        % translation along the X, Y, and Z axes.
        %
        T = [1 0 0 x; 0 1 0 y; 0 0 1 z; 0 0 0 1];
    end


    function vsize = maxv(V)
        %
        % Look at the xyz elements of V, and determine the maximum
        % values during some simple rotations.
        vsize = max(max(V));
        % Rotate it a bit, and check for max and min vertex for viewing.
        for ang = 0:10:360
            vsizex = rx(ang)*V;
            maxv = max(max(vsizex));
            if maxv > vsize, vsize = maxv; end
            vsizey = ry(ang)*V;
            maxv = max(max(vsizey));
            if maxv > vsize, vsize = maxv; end
            vsizez = rz(ang)*V;
            maxv = max(max(vsizez));
            if maxv > vsize, vsize = maxv; end
            vsizev = rx(ang)*ry(ang)*rz(ang)*V;
            maxv = max(max(vsizev));
            if maxv > vsize, vsize = maxv; end
        end
    end

    function [fout, vout, cout] = rndread(filename)
        % Reads CAD STL ASCII files, which most CAD programs can export.
        % Used to create Matlab patches of CAD 3D data.
        % Returns a vertex list and face list, for Matlab patch command.
        
        fid=fopen(filename, 'r'); %Open the file, assumes STL ASCII format.
        if fid == -1
            error('File could not be opened, check name or path.')
        end
        %
        % Render files take the form:
        %
        %solid BLOCK
        %  color 1.000 1.000 1.000
        %  facet
        %      normal 0.000000e+00 0.000000e+00 -1.000000e+00
        %      normal 0.000000e+00 0.000000e+00 -1.000000e+00
        %      normal 0.000000e+00 0.000000e+00 -1.000000e+00
        %    outer loop
        %      vertex 5.000000e-01 -5.000000e-01 -5.000000e-01
        %      vertex -5.000000e-01 -5.000000e-01 -5.000000e-01
        %      vertex -5.000000e-01 5.000000e-01 -5.000000e-01
        %    endloop
        % endfacet
        %
        % The first line is object name, then comes multiple facet and vertex lines.
        % A color specifier is next, followed by those faces of that color, until
        % next color line.
        %
        CAD_object_name = sscanf(fgetl(fid), '%*s %s');  %CAD object name, if needed.
        %                                                %Some STLs have it, some don't.
        vnum=0;       %Vertex number counter.
        report_num=0; %Report the status as we go.
        VColor = 0;
        %
        while feof(fid) == 0                    % test for end of file, if not then do stuff
            tline = fgetl(fid);                 % reads a line of data from file.
            fword = sscanf(tline, '%s ');       % make the line a character string
            % Check for color
            if strncmpi(fword, 'c',1) == 1;    % Checking if a "C"olor line, as "C" is 1st char.
                VColor = sscanf(tline, '%*s %f %f %f'); % & if a C, get the RGB color data of the face.
            end                                % Keep this color, until the next color is used.
            if strncmpi(fword, 'v',1) == 1;    % Checking if a "V"ertex line, as "V" is 1st char.
                vnum = vnum + 1;                % If a V we count the # of V's
                report_num = report_num + 1;    % Report a counter, so long files show status
                if report_num > 249;
                    disp(sprintf('Reading vertix num: %d.',vnum));
                    report_num = 0;
                end
                v(:,vnum) = sscanf(tline, '%*s %f %f %f'); % & if a V, get the XYZ data of it.
                c(:,vnum) = VColor;              % A color for each vertex, which will color the faces.
            end                                 % we "*s" skip the name "color" and get the data.
        end
        %   Build face list; The vertices are in order, so just number them.
        %
        fnum = vnum/3;      %Number of faces, vnum is number of vertices.  STL is triangles.
        flist = 1:vnum;     %Face list of vertices, all in order.
        F = reshape(flist, 3,fnum); %Make a "3 by fnum" matrix of face list data.
        %
        %   Return the faces and vertexs.
        %
        fout = F';  %Orients the array for direct use in patch.
        vout = v';  % "
        cout = c';
        %
        fclose(fid);
    end
end
