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
fTable = cell(edgeCount, 7);    %sNode / eNode / current edge index / parents edge index / °¢µµ º¤ÅÍ / depth / ºÐ±â °¹¼ö
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
        end
    end
end

disp(fTable);