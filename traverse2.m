function traverse2(root, adjM, pts)
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
        pDepth = fTable{fTable{n,4},6};
        if fTable{fTable{n,4},7} > 1
            fTable{n,6} = pDepth+1;
        else
            fTable{n,6} = pDepth;
        end
    end
end

disp(fTable);