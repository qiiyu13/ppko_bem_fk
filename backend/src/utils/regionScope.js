// Region hierarchy is VILLAGE -> RW -> RT. Patients carry regionId = an RT (or
// whichever level they were assigned). An admin scoped to a region must see
// every user at that region OR any descendant, so anchoring at a VILLAGE id
// still matches the RW and RT rows beneath it.
//
// Returns a Prisma `user.where` fragment (the `region` relation filter) that
// matches the given region and its direct + grandchild descendants.
const regionScopeFilter = (regionId) => ({
  region: {
    OR: [
      { id: regionId },
      { parentId: regionId },
      { parent: { parentId: regionId } },
    ],
  },
});

module.exports = { regionScopeFilter };
