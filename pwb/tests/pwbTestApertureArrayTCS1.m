function [ isPass ] = pwbTestApertureArrayTCS1( isPlot )
%pwbTestApertureArrayTCS1 -
%
% Reproduces Fig. 3 from [1].
% 
% References:
%
% [1] U. Paoletti, T. Suga and H. Osaka, 
%     "Average transmission cross section of aperture arrays in electrically large complex enclosures",
%     2012 Asia-Pacific Symposium on Electromagnetic Compatibility, Singapore, 2012, pp. 677-680.
%     DOI: 10.1109/APEMC.2012.6237888
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
% Date: 07/03/2017

  tol = 1e-2;
  isValid=@(x,y) all( abs( x - y ) < tol );
  isPass = true;
 
  if( nargin == 0 )
    isPlot = false;
  end % if
  
  c0 = 299792458;
  
  f = logspace( log10( 200e6 ) , log10( 6e9 ) , 100 )';
 
  % Wavenumber.
  k = 2.0 .* pi .* f ./ c0;
  
  %
  % Square aperture on square lattice.
  %
  
  % From [1, Table I].
  arrayPeriodX = 7e-3;
  arrayPeriodY = 7e-3;
  apertureSpacing = 2e-3;
  thickness = 1e-3;
  
  % Side lengths of aperture.
  side_x = arrayPeriodX - apertureSpacing;
  side_y = arrayPeriodY - apertureSpacing;

  % Area of primitive unit cell.
  cellArea = arrayPeriodX * arrayPeriodY;
  
  % Array size is set to unity.
  array_size_x = 1.0;
  array_size_y = 1.0;
  array_area = array_size_x * array_size_y;
  
  % Aperture polarisabilitites.  
  [ apertureArea , alpha_mxx , alpha_myy , alpha_ezz ] = pwbApertureSquarePol( side_x );

  % Array porosity.
  porosity = apertureArea / arrayPeriodX / arrayPeriodY;
  fprintf( 'Square array porosity: %.2f\n' , porosity );

  % Square aperture cut-off frequency.
  cutOffFreq = c0 / 2.0 / max( [ side_x , side_y ] );
  
  % TCS.  
  [ TCS_sq , TE_sq ] = pwbApertureArrayTCS( f , array_area , arrayPeriodX , arrayPeriodY , cellArea , ...
    thickness ,  apertureArea , alpha_mxx , alpha_myy , alpha_ezz , cutOffFreq ); 
 
  %
  % Hexagonal apertures on parallelogram lattice.
  %
  
  % From [1, Table I].
  arrayPeriodX = 5e-3;
  arrayPeriodY = 5e-3 * sqrt( 3 );
  apertureSpacing = 1e-3;
  thickness = 1e-3;
  
  % Side length of hexagonal aperture.
  side = ( arrayPeriodX - apertureSpacing ) / sqrt( 3 );
  
  % Perpendicular distance from centre of aperture to mid-poinr of a side. 
  h = ( arrayPeriodX - apertureSpacing ) / 2;
  
  % Area of primitive unit cell.
  cellArea = arrayPeriodX * arrayPeriodY / 2.0;

  % Array size is set to unity.
  array_size_x = 1.0;
  array_size_y = 1.0;
  array_area = array_size_x * array_size_y;
    
  % Aperture polarisabilitites - use circular aperture of same area.
  A_hex = 3 * sqrt( 3 ) / 2 * side^2;
  radius = sqrt( A_hex / pi );
  [ apertureArea , alpha_mxx , alpha_myy , alpha_ezz ] = pwbApertureCircularPol( radius );
  
  % Array porosity.
  porosity = ( 1 - apertureSpacing / arrayPeriodX )^2;
  fprintf( 'Hexagonal array porosity: %.2f\n' , porosity );

  % Hexagonal aperture cut-off frequency.
  cutOffFreq = c0 / pi / side;
  
  % TCS.
  [ TCS_hex , TE_hex ] = pwbApertureArrayTCS( f , array_area , arrayPeriodX , arrayPeriodY , cellArea , ...
    thickness , apertureArea , alpha_mxx , alpha_myy , alpha_ezz , cutOffFreq );
  
  % Validation data.
  baseName = fileparts( which( mfilename ) );
  data = dlmread( [ baseName , '/pwbTestApertureArrayTCS1_square_analytic.asc' ] ); 
  f_sq_val = 1e9 .* data(:,1);
  TE_sq_val = 4.0 .* 10.^( data(:,2) / 10.0 );
  data = dlmread( [ baseName , '/pwbTestApertureArrayTCS1_hexagonal_analytic.asc' ] ); 
  f_hex_val = 1e9 .* data(:,1);
  TE_hex_val = 4.0 .* 10.^( data(:,2) / 10.0 );

  isPass = isPass && isValid( TE_sq , interp1( f_sq_val , TE_sq_val , f ) );
  isPass = isPass && isValid( TE_hex , interp1( f_hex_val , TE_hex_val , f )  );
  
  %
  % Plots.
  %
  
  if( isPlot )
  
    figure()
    plot( f ./ 1e9 , db10( 0.25 .* TE_sq ) , 'r-' );
    hold on;
    plot( f_sq_val ./ 1e9 , db10( 0.25 .* TE_sq_val ) , 'r:o' );
    plot( f ./ 1e9 , db10( 0.25 .* TE_hex ) , 'b-' );
    plot( f_hex_val ./ 1e9 , db10( 0.25 .* TE_hex_val ) , 'b:^' );
    grid( 'on' );
    xlabel( 'Frequency (GHz)' );
    ylabel( '<\sigma^t> / A (dB)' );
    xlim( [ 0 , 6 ] );
    ylim( [ -45 , -20 ] );
    legend( 'Square, toolbox' , 'Square, Paoletti et al' , 'Hexagonal, toolbox' , 'Hexagonal, Paoletti et al' , 'location' , 'southeast' );
    print( '-depsc2' , 'pwbTestApertureArrayTCS1.eps' );
    hold off;

  end % if

end % function
