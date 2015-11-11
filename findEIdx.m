function idx = findEIdx(labelSet, node1, node2)
idx = 0;
for n = 1:size(labelSet,1)
    if (labelSet{n,1} == node1 && labelSet{n,2} == node2) || ...
            (labelSet{n,1} == node2 && labelSet{n,2} == node1)
        idx = n; return
    end
end
