---
{title: sw_extendlattice( ), summary: creates superlattice, keywords: sample, sidebar: sw_sidebar,
  permalink: sw_extendlattice.html, folder: swfiles, mathjax: 'true'}

---
 
[aList, SSext] = SW_EXTENDLATTICE(nExt, aList, {SS})
 
It creates a superlattice and all redefines all given bond for the larger
superlattice.
 
Input:
 
nExt          Number of unit cell extensions, dimensions are [1 3].
aList         List of the atoms, produced by spinw.matom.
SS            Interactions matrices in the unit cell, optional.
 
Output:
 
aList         Parameters of the magnetic atoms.
aList.RRext   Positions of magnetic atoms, assuming an extended unit
              cell, dimensions are [3 nMagExt].
aList.Sext    Spin length of the magnetic atoms, dimensions are
              [1 nMagExt].
 
SSext         Interaction matrix in the extended unit cell, struct type.
              In the struct every field is a matrix. Every column of the
              matrices describes a single interaction.
SSext.iso     Isotropic exchange interactions.
SSext.ani     Anisotropic exchange interations.
SSext.dm      Dzyaloshinsky-Moriya interaction terms.
SSext.gen     General 3x3 matrix contains the exchange interaction.
 
See also SPINW.INTMATRIX.
 
