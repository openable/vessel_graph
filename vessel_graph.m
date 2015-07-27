function vessel_graph
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
            [((scr(3)-980)/2) ((scr(4)-840)/2) 980 840], 'KeyPressFcn',@onFigKey);
        h.ax = axes('Parent',h.fig, 'ButtonDownFcn',@onMouseDown, ...
            'XLim',[0 1000], 'YLim',[0 1000], 'XTick',[], 'YTick',[], 'Box','on', ...
            'Units','pixels', 'Position',[160 20 800 800]);

        %radio code move
        h.rA = uicontrol('Style','radiobutton', 'Parent',h.fig, 'String','Artery', ...
            'Position',[20 800 60 20],'Value',1,'Callback',@onArtery);
        h.rV = uicontrol('Style','radiobutton', 'Parent',h.fig, 'String','Vein', ...
            'Position',[90 800 60 20],'Callback',@onVein);
        h.list = uicontrol('Style','listbox', 'Parent',h.fig, 'String',{}, ...
            'Min',1, 'Max',1, 'Value',-1, 'FontName', 'Fixedsys', 'FontSize', 10, ...
            'Position',[20 170 130 620], 'Callback',@onSelect); % 140
        h.labelText = uicontrol('Style','text', 'Parent',h.fig, 'String',{}, ...
            'String', '이름:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 140 40 20]);
        h.labelEdit = uicontrol('Style','edit', 'Parent',h.fig, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 140 60 20], 'KeyPressFcn',@onEditKey);
        h.labelSet = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','설정', ...
            'Position',[125 140 25 20], 'Callback',@onLabelSet, 'Enable', 'off', 'KeyPressFcn',@onSetKey);
        h.delete = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','점/선분 삭제', ...
            'Position',[20 110 130 20], 'Callback',@onDelete, 'Enable', 'off');
        h.clear = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','초기화', ...
            'Position',[20 80 130 20], 'Callback',@onClear);
        h.import = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','가져오기', ...
            'Position',[20 50 130 20], 'Callback',@onImport);
        h.export = uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','내보내기', ...
            'Position',[20 20 130 20], 'Callback',@onExport);


        
        h.cmenu = uicontextmenu('Parent',h.fig);
        h.menu = uimenu(h.cmenu, 'Label','Show verticies', 'Checked','off', ...
            'Callback',@onCMenu);
        set(h.list, 'UIContextMenu',h.cmenu)

        % 동맥 (Atery)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.pts = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prev = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 선분 목록
        h.edges = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.vertices = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vessels = [];
        
        
        % 정맥 (Vein)
        % 꼭지점.. 직선에서 라인스타일을 None으로 해서 선은 안그리고 Marker만 찍게 함.
        h.ptsV = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % 마우스 오른족 버튼으로 선택 했을 때 녹색 테두리 - 선분 그리기 위해
        h.prevV = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',20, 'Color','g', ...
            'LineStyle','none', 'LineWidth',2);
        % 선분 목록
        h.edgesV = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','b');
        % 꼭지점 라벨링 표시용 변수(기억용 아님). V1, V2, ... 순서대로
        h.verticesV = [];
        % 선분 라벨링 표시용 변수(기억용 아님). E1, E2, ... 순서대로
        h.vesselsV = [];
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
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+마우스 왼쪽 클릭
                onLabelEdit();
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
            end
        else
            % 정맥 처리 (Vein) 
            if strcmpi(get(h.fig,'SelectionType'), 'Normal')
                % add a new node
                ptsVein(end+1,:) = p(1,1:2);
                adjVein(end+1,end+1) = 0;
            elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+마우스 왼쪽 클릭
                onLabelEdit();
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
            end
        end

        % update GUI
        selectIdxAtery = [];
        selectIdxVein = [];
        redraw()
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
    %            prevIdx = [];              %밑에서 초기화 하니 불필요 예상됨

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
        set(h.list, 'Value',1)
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

    function onLabelEdit(~,~)
        set(h.labelEdit, 'Enable', 'on');
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
        set(h.edges, 'XData',p(:,1), 'YData',p(:,2))
        if ishghandle(h.vessels), delete(h.vessels); end
        h.vessels = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
             strcat(labelAtery(:,3)), ...  % label(:)
             'HitTest','off', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold', ...
             'VerticalAlign','bottom', 'HorizontalAlign','left');
        % 정맥
        p = nan(3*nnz(adjVein),2);
        for q = 1:size(labelVein,1)
            p(1+3*(q-1),:) = ptsVein(labelVein{q,1},:);
            p(2+3*(q-1),:) = ptsVein(labelVein{q,2},:);
        end
        set(h.edgesV, 'XData',p(:,1), 'YData',p(:,2))
        if ishghandle(h.vesselsV), delete(h.vesselsV); end
        h.vesselsV = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
             strcat(labelVein(:,3)), ...  % labelV(:)
             'HitTest','off', 'FontSize', 10, 'Color', 'b', 'FontWeight', 'bold', ...
             'VerticalAlign','bottom', 'HorizontalAlign','left');

        % 점 그리기 단계
        % 동맥
        set(h.pts, 'XData', ptsAtery(:,1), 'YData',ptsAtery(:,2))
        set(h.prev, 'XData', ptsAtery(prevIdxAtery,1), 'YData',ptsAtery(prevIdxAtery,2))
        if ~isempty(selectIdxAtery)
            set(h.vessels(selectIdxAtery), 'Color', 'g')
        end       
        % 정맥
        set(h.ptsV, 'XData', ptsVein(:,1), 'YData',ptsVein(:,2))
        set(h.prevV, 'XData', ptsVein(prevIdxVein,1), 'YData', ptsVein(prevIdxVein,2))
        if ~isempty(selectIdxVein)
            set(h.vesselsV(selectIdxVein), 'Color', 'g')
        end
        
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
        if ishghandle(h.vertices), delete(h.vertices); end
        if showVertices
            set(h.menu, 'Checked','on')
            h.vertices = text(ptsAtery(:,1)+2.5, ptsAtery(:,2)+2.5, ...
                strcat('a', num2str((1:size(ptsAtery,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', [0.1,0.1,0.1]*7, 'FontWeight', 'normal', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left');
        else
            set(h.menu, 'Checked','off')
        end
        % 정맥
        if ishghandle(h.verticesV), delete(h.verticesV); end
        if showVertices
            set(h.menu, 'Checked','on')
            h.verticesV = text(ptsVein(:,1)+2.5, ptsVein(:,2)+2.5, ...
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
