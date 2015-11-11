function lTable = traverse2(root, adjM, pts)
parent = CList();
path = CQueue();
path.push(root);
edgeCount = 0;

while ~path.isempty()
    node = path.pop();
    parent.pushtorear(node);
    children = find(adjM(node,:) == 1);
    for n = 1:length(children)
       if ~parent.contains(children(n));
          path.push(children(n));
          edgeCount = edgeCount + 1;
       end
    end
end


parent.removeall();
fTable = cell(edgeCount, 7);    %sNode / eNode / current edge index / parents edge index / ���� ���� / depth / �б� ����
path.push(root);
eIndex = 0;

while ~path.isempty()
    sNode = path.pop();
    parent.pushtorear(sNode);
    children = find(adjM(sNode,:) == 1);
    for n = 1:length(children)
        eNode = children(n);
        if ~parent.contains(eNode);
            path.push(eNode);
            eIndex = eIndex + 1;
            fTable{eIndex,1} = sNode;
            fTable{eIndex,2} = eNode;
            fTable{eIndex,3} = eIndex;
            
            % �������� ������ ���̾��� ������ ã�� �θ� ���� ��ȣ �Ҵ�
            for m = 1:size(fTable,1)
                if fTable{m,2} == sNode
                    fTable{eIndex,4} = fTable{m,3};
                    break
                end
            end
            
            % �б� ������ �θ�� 1 ���� �Ҵ�
            branch = find(adjM(eNode,:) == 1);
            fTable{eIndex,7} = length(branch)-1;
        end
    end
end

for n = 1:size(fTable,1)
    % �θ� ���а� ���� ���� ���� ���� ���
    % http://kr.mathworks.com/matlabcentral/newsreader/view_thread/148079
    if ~isempty(fTable{n,4})
        %���� ������ �������� �߽����� ���� ����
        pVector = pts(fTable{fTable{n,4},1},:) - pts(fTable{fTable{n,4},2},:); %���������� ������ �� ��
        cVector = pts(fTable{n,2},:) - pts(fTable{n,1},:); %������ ������ ������ ��
        
        pUnit = pVector / norm(pVector);
        cUnit = cVector / norm(cVector);
        theta = acos(dot(pUnit, cUnit));
        
        fTable{n,5} = theta*180/pi;
    end
    
    % �θ� ���п��� ���� ���� �б� ���ο� ���� depth �� ����, 1���� depth ��� ���
    if isempty(fTable{n,4})
        fTable{n,6} = 1;    % root�� ������ depth 1�� ����
    else
%         �б� X, �θ� depth ����
%         �б� X, 90�� ���ϸ� �θ� depth + 1
%         �б� O, ������ 145�� �̻��̸� �θ� depth ����
%         �б� O, ������ 145�� ������ �� �θ� depth + 1
        pDepth = fTable{fTable{n,4},6};

        if fTable{fTable{n,4},7} > 1
            if fTable{n,5} > 145
                fTable{n,6} = pDepth;
            else
                fTable{n,6} = pDepth+1;
            end
        else
            if fTable{n,5} < 90
                fTable{n,6} = pDepth+1;
            else
                fTable{n,6} = pDepth;
            end
        end
    end
end

lTable = cell(edgeCount, 3);    % sNode / eNode / label
lTable(:,1:2) = fTable(:,1:2);
for n = 1:edgeCount
    lTable{n,3} = autoLabel(fTable, lTable, n);
end

%disp(fTable);
%disp(lTable);
end

function label = autoLabel(fTable, lTable, line)
list = cell(5,1);
list{1,1} = 'Ao';
list{2,1} = {{'Ao', 'CA'}, {'Ao', 'SMA'}, {'Ao', 'IMA'}, {'Ao', 'RCIA'}, {'Ao', 'LCIA'}};
list{3,1} = {{'Ao', 'CA', 'LGA'}, {'Ao', 'CA', 'CHA'}, {'Ao', 'CA', 'SA'}};
list{4,1} = {{'Ao', 'CA', 'CHA', 'PHA'}, {'Ao', 'CA', 'CHA', 'GDA'}, {'Ao', 'CA', 'SA', 'LGEA'}};
list{5,1} = {{'Ao', 'CA', 'CHA', 'PHA', 'RGA'}, {'Ao', 'CA', 'CHA', 'PHA', 'LHA'}, {'Ao', 'CA', 'CHA', 'PHA', 'RHA'}, {'Ao', 'CA', 'CHA', 'GDA', 'RGEA'}};

    depth = fTable{line, 6};
    if depth == 1
        label = list{1,1}; return
    else
        pEdge = fTable{line, 4};
        pLabel = lTable{pEdge, 3};
        target = list{depth};
        index = [];
        for n = 1:size(target, 2)
            if ~strcmp(target{n}{depth-1}, pLabel)
                index = [index n];
            end
        end
        target(index) = [];
        
        if depth == fTable{pEdge,6}
            label = pLabel; return
        elseif strcmp(pLabel, 'Unknown')
            label = 'Unknown'; return
        elseif size(target,2) > 1
            label = target{randi([1 size(target,2)])}{depth}; return
        end
    end
    
    label = 'Unknown';
end