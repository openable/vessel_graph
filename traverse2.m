function traverse2(root, adjM)
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
fTable = cell(edgeCount, 7);    %sNode / eNode / current edge index / parents edge index / 각도 벡터 / depth / 분기 갯수
path.push(root);
eIndex = 0;
fTable{1,4} = 0;        %root 시작점의 parents edge는 없으니 0으로

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
            
            for m = 1:size(fTable,1)
                if fTable{m,2} == sNode
                    fTable{eIndex,4} = fTable{m,3};
                    break
                end
            end
        end
    end
end

disp(fTable);