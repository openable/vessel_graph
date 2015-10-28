function traverse(root, adjM)
parent = [];
path = CQueue();
path.push(root);

while ~path.isempty()
    node = path.pop();
    disp(node);
    parent = [parent, node];
    children = find(adjM(node,:) == 1);
    for n = 1:length(children)
       if ~any(children(n) == parent)
          path.push(children(n));
       end
    end
end