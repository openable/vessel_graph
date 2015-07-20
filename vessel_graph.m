function vessel_graph
%     http://stackoverflow.com/questions/17029214/mathematic-graphs-with-matlab-gui
%
%     It all boils down to handling the ButtonDownFcn callback of the axis object,
%     and querying the location of the last mouse click using the CurrentPoint property.
% 
%     Here is a list of the possible ways to interact with the GUI:
% 
%     - left-click inside the axis to create vertices
%     - right-click on two nodes to create an edge
%     - use the listbox to select and highlight nodes.
%       Use the "delete" button to remove the selected vertex.
%     - The "clear" button resets everything
%     - The "export" button create two variables in the base workspace
%       containing the vertices 2D coordinates (N-by-2 matrix) and
%       the edges (as a sparse N-by-N matrix).
%       You can use those variables with other graph functions as usual:
%         gplot(adj, xy, 'b.-')
%     - Finally you can right click on the listbox.
%       This will bring up a popup menu, containing the option
%       to display labels for the vertices.
% 
%     You can extend the above code to assign values to vertices.
%     For example you could use the callback function of the listbox
%     to assign values to vertices (display an input dialog
%     when the user selects an item from the list).
%     You could also use the same technique shown of
%     handling the ButtonDownFcn callback.
%     Similarly you could create a second listbox to display the edges
%     and handle the assignment of values in the same manner... I will that part to you :)
% 선분 관련 주석 달았음. 선분 편집할 텍스트 창 생성
    % data
    showVertices = false;   % flag to determine whether to show node labels
    prevIdx = [];         % keeps track of 1st node clicked in creating edges
    selectIdx = [];       % used to highlight node selected in listbox
    pts = zeros(0,2);     % x/y coordinates of vertices
    adj = sparse([]);     % sparse adjacency matrix (undirected)    % 선분 연결 정보 기억
    label = cell(0,3);      % 선분 레이블 저장용 변수, 첫번째 점 / 두번째 점 / 레이블 이름
    

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
            'Min',1, 'Max',1, 'Value',1, ...
            'Position',[20 170 130 620], 'Callback',@onSelect); % 140
        h.lable_text = uicontrol('Style','text', 'Parent',h.fig, 'String',{}, ...
            'String', 'Label:', 'HorizontalAlignment', 'left', 'FontSize', 10, ...
            'Position',[20 140 40 20]);
        h.lable_edit = uicontrol('Style','edit', 'Parent',h.fig, 'String',{}, ...
            'HorizontalAlignment', 'left', 'Enable', 'off', ...
            'Position',[60 140 60 20], 'Callback',@onLableEdit);
        uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','Set', ...
            'Position',[125 140 25 20], 'Callback',@onLableEdit);
        uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','Delete', ...
            'Position',[20 110 130 20], 'Callback',@onDelete);
        uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','Clear', ...
            'Position',[20 80 130 20], 'Callback',@onClear);
        uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','Import', ...
            'Position',[20 50 130 20], 'Callback',@onImport);
        uicontrol('Style','pushbutton', 'Parent',h.fig, 'String','Export', ...
            'Position',[20 20 130 20], 'Callback',@onExport);


        
        h.cmenu = uicontextmenu('Parent',h.fig);
        h.menu = uimenu(h.cmenu, 'Label','Show verticies', 'Checked','off', ...
            'Callback',@onCMenu);
        set(h.list, 'UIContextMenu',h.cmenu)

        % 꼭지점
        h.pts = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
        % 리스트 상에서 선택 했을 때 노란색으로 표시
        h.selected = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','y', ...
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
            h.pts = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','b', ...
            'LineStyle','none');
            h.edges = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','r');
            redraw()
        else    %h.rV.Value == 1
            h.pts = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'Marker','o', 'MarkerSize',10, 'MarkerFaceColor','r', ...
            'LineStyle','none');
            h.edges = line(NaN, NaN, 'Parent',h.ax, 'HitTest','off', ...
            'LineWidth',2, 'Color','b');
            redraw()
        end
    end

    function onMouseDown(~,~)
        % get location of mouse click (in data coordinates)
        p = get(h.ax, 'CurrentPoint');

        % determine whether normal left click was used or otherwise
        if strcmpi(get(h.fig,'SelectionType'), 'Normal')
            % add a new node
            pts(end+1,:) = p(1,1:2);
            adj(end+1,end+1) = 0;
        elseif strcmpi(get(h.fig,'SelectionType'), 'Extend')  %shift+마우스 왼쪽 클릭
            onLabelSet();
        else
            % add a new edge (requires at least 2 nodes)
            if size(pts,1) < 2, return; end

            % hit test (find node closest to click location: euclidean distnce)
            [dst,idx] = min(sum(bsxfun(@minus, pts, p(1,1:2)).^2,2));
            if sqrt(dst) > 8, return; end

            if isempty(prevIdx)
                % starting node (requires a second click to finish)
                prevIdx = idx;
            else
                % add the new edge % 선분 생성 단계
                adj(prevIdx,idx) = 1;
                m = size(label,1);
                label{m+1,1} = prevIdx;
                label{m+1,2} = idx;
                label{m+1,3} = strcat('E', num2str(m+1));
                prevIdx = [];
            end
        end

        % update GUI
        selectIdx = [];
        redraw()
    end

    function onDelete(~,~)
        % check that list of nodes is not empty
        if isempty(pts), return; end

        % delete selected node
        idx = get(h.list, 'Value');        
        pts(idx,:) = [];
        % 선분 삭제 단계
        adj(:,idx) = [];
        adj(idx,:) = [];

        % clear previous selections
        if prevIdx == idx
            prevIdx = [];
        end
        selectIdx = [];

        % update GUI
        set(h.list, 'Value',max(min(idx,size(pts,1)),1))
        redraw()
    end

    function onClear(~,~)
        % reset everything
        prevIdx = [];
        selectIdx = [];
        pts = zeros(0,2);
        adj = sparse([]);

        % update GUI
        set(h.list, 'Value',1)
        redraw()
    end

    function onExport(~,~)
        % export nodes and adjacency matrix to base workspace
        assignin('base', 'adj',(adj+adj')>0)  % make it symmetric% 선분 시메트릭하게 복사
        assignin('base', 'xy',pts)
    end

    function onSelect(~,~)
        % update index of currently selected node
        selectIdx = get(h.list, 'Value');
        redraw()
    end

    function onCMenu(~,~)
        % flip state
        showVertices = ~showVertices;
        redraw()
    end

    function onLabelSet(~,~)
        set(h.lable_edit, 'Enable', 'on');
    end

    function redraw()
        % edges % 선분 그리기 단계
        p = nan(3*nnz(adj),2);
        for q = 1:size(label,1)
            p(1+3*(q-1),:) = pts(label{q,1},:);
            p(2+3*(q-1),:) = pts(label{q,2},:);
        end
%        [i,j] = find(adj);
%        p(1:3:end,:) = pts(i,:);
%        p(2:3:end,:) = pts(j,:);
        set(h.edges, 'XData',p(:,1), 'YData',p(:,2))
        if size(label,1) > 0
            eColor = 'r'; if h.rV.Value, eColor = 'b'; end
            for q = 1:size(label,1)
                label_list(q,1:size(label{q,3},2)) = label{q,3};
            end
            h.vessels = text((p(1:3:end,1)+p(2:3:end,1))/2+8, (p(1:3:end,2)+p(2:3:end,2))/2+8, ...
                 label_list, ...  % label(:)
                 'HitTest','off', 'FontSize', 10, 'Color', eColor, 'FontWeight', 'bold', ...
                 'VerticalAlign','bottom', 'HorizontalAlign','left');
    %             strcat('E', num2str((1:(size(p,1)/3))')), ...  % label(:)
    %                'ButtonDownFcn', @onLabelSet, ...
        end

        % nodes
        set(h.pts, 'XData',pts(:,1), 'YData',pts(:,2))
        set(h.prev, 'XData',pts(prevIdx,1), 'YData',pts(prevIdx,2))
        set(h.selected, 'XData',pts(selectIdx,1), 'YData',pts(selectIdx,2))

        % list of nodes
        set(h.list, 'String',strcat(num2str((1:size(pts,1))'), num2str(pts,': (%.2f, %.2f)')))

        % node labels
        if ishghandle(h.vertices), delete(h.vertices); end
        if showVertices
            set(h.menu, 'Checked','on')
            vColor = 'b'; if h.rV.Value, vColor = 'r'; end
            h.vertices = text(pts(:,1)+2.5, pts(:,2)+2.5, ...
                strcat('V', num2str((1:size(pts,1))')), ...
                'HitTest','off', 'FontSize', 8, 'Color', vColor, 'FontWeight', 'bold', ...
                'VerticalAlign','bottom', 'HorizontalAlign','left');
        else
            set(h.menu, 'Checked','off')
        end

        % force refresh
        drawnow
    end

end
