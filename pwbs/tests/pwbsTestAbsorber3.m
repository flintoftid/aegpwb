function [ isPass ] = pwbsTestAbsorber3()
% pwbsTestAbsorber3 - 
%

% This file is part of aegpwb.
%
% aegpwb power balance toolbox and solver.
% Copyright (C) 2016 Ian Flintoft
%
% aegpwb is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% aegpwb is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with aegpwb.  If not, see <http://www.gnu.org/licenses/>.
%
% Author: I. D Flintoft
% Date: 19/08/2016

  tol = 100 * eps;
  isValid=@(x,y) all( abs( x - y ) < tol );
  isPass = true;
    
  dlmwrite( 'pwbsTestAbsorber3.asc' , [ 0.99e9 , 1.0 ; 1.0e9 , 1.0 ; 1.1e9 , 1.0 ] , ' ' );
    
  f = [ 1e9 ];
  pwbm = pwbsInitModel( f , 'TestAbsorber3' );
  pwbm = pwbsAddCavity( pwbm , 'C' , 'Generic'  , { 1.0 , 1.0 , Inf , 1.0 } );
  pwbm = pwbsAddAbsorber( pwbm , 'AB' , 'C' , 1 , 'FileACS' , { 4.0 , 'pwbsTestAbsorber3.asc' } );
  pwbm = pwbsAddSource( pwbm , 'S' , 'Direct' , 'C' , { 1 } );
  pwbm = pwbsSolveModel( pwbm );
  
  delete( 'pwbsTestAbsorber3.asc' );
    
  [ data , units ] = pwbsGetOutput( pwbm , 'Absorber' , 'AB' , { 'ACS' , 'AE' , 'absorbedPower' } );
  isPass = isPass && isValid( data{1} , 1.0 );
  isPass = isPass && isValid( data{2} , 1.0 );
  isPass = isPass && isValid( data{3} , 1.0 );
  [ data , units ] = pwbsGetOutput( pwbm , 'Cavity' , 'C' , { 'powerDensity' } );
  isPass = isPass && isValid( data{1} , 1.0 );
  
end % function
