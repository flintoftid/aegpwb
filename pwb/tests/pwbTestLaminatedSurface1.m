function [ isPass ] = pwbTestLaminatedSurface1()
% pwbTestLaminatedSurface1 -
%

% This file is part of aegpwb.
%
% aegpwb power balance toolbox and solver.
% Copyright (C) 2016 Ian Flintoft <ian.flintoft@googlemail.com>
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
% Author: Ian Flintoft <ian.flintoft@googlemail.com>
% Date: 19/08/2016

  tol = 1e-6;
  isValid=@(x,y) all( abs( x - y ) < tol );
  isPass = true;
  
  f = logspace( log10( 10e6 ) , log10(1e9) , 20 )';
  area = 4.0;
  epsc_r = 2.0;
  sigma = 1e3;
  mu_r = 1.0;
  sigmam = 0.0;
  
  [ ACS1 , AE1 ] = pwbDielectricSurface( f , area , epsc_r , sigma , mu_r );
  [ ACS2 , AE2 ] = pwbLaminatedSurface( f , area , [] , epsc_r , sigma , mu_r , sigmam );

  isPass = isPass && isValid( ACS1 , ACS2 );
  isPass = isPass && isValid( AE1 , AE2 );
 
end % function
