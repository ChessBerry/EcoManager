local oldFn = LayoutResourceGroup

function LayoutResourceGroup(group, groupType)
    oldFn(group, groupType)
    LayoutHelpers.AtLeftIn(group.overflow, group.rate, 60)
    LayoutHelpers.AtVerticalCenterIn(group.overflow, group)
end
