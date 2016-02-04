function A = AssembleMixedDomainMatrix(geo,femrule1D,femrule2D,bilinearform)
% Assembles system matrix according to the bilinearform formulation and a  finite element rule
% specified by user input 
% INPUT: geo geometry / mesh
%        femrule finite element rule 
%        bilinearform function handle to bilinear form
%
%
% (c) Daniela Fusseder, Technische Universität Kaiserslautern, 2015

ndof = geo.nmbNodes;
nelem = geo.nmbElements;


% allocate space
At.vals = zeros(nelem*9,1);
At.cols = zeros(nelem*9,1);
At.rows = zeros(nelem*9,1);


% loop over all elements
for i=1:nelem
    
    % get global basis properties
    globalBasis = geo.globalNodeIndices(i);
    columns = repmat(globalBasis,1,3);
    rows = [repmat(globalBasis(1),1,3),repmat(globalBasis(2),1,3),repmat(globalBasis(3),1,3)];

    
    % get local element properties
    K = geo.getLocalElement(i);
    
    % get element entries
    KA = elementEntries( K,femrule1D,femrule2D,bilinearform );
    
    % save everything in arrays       
    pos = (i-1)*9+1;
    At.cols(pos:pos+8) = columns;
    At.rows(pos:pos+8) = rows;
    At.vals(pos:pos+8) = KA;
        
end

% assemble sparse global matrix
A = sparse(At.rows,At.cols,At.vals);
clear At;

end


function values = elementEntries(K,femrule1D,femrule2D,bilinearform)
% get quadrature points
Gauss = Quad2DTriangle(femrule2D.m);
W = Gauss.getWeights;
points = Gauss.getQuadPointInfo(K);

% pre evaluate element basis functions
[~,Z] = Gauss.trafo(K);
basisfunctions1D = cell(3,1);
basisfunctions2D = cell(3,1);
for i=1:3
    basisfunctions1D{i} = femrule1D.basis(i,points.refx,points.refy,Z);
    basisfunctions2D{i} = femrule2D.basis(i,points.refx,points.refy,Z);
end

% test bilinearform with each basis function combination
detTrafo = Gauss.detTrafo(K);
values = zeros(3);
for i=1:3
    basisi = basisfunctions1D{i};
    for j=1:3        
        basisj = basisfunctions2D{j};        
        Y = bilinearform( basisi,basisj, points);
    
        % Gauss integration
        values(i,j) = W*Y'*detTrafo;
    end
end

values = reshape(values,1,9);
end
