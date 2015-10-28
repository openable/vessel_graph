function traverse2(root, adjM)
parent = CList();
path = CQueue();
path.push(root);

while ~path.isempty()
    node = path.pop();
    disp(node);
    parent.pushtorear(node);
    children = find(adjM(node,:) == 1);
    for n = 1:length(children)
       if ~parent.contains(children(n));
          path.push(children(n));
       end
    end
end