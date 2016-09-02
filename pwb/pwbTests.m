function pwbTests()
%
% pwbTests - Run yoolbox test-suite
%
% pwbTests()
%

% aegpwb power balance toolbox and solver.
% Copyright (C) 2016 Ian Flintoft
%
% aeggpwb is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% aeggpwb is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with aeggpwb.  If not, see <http://www.gnu.org/licenses/>.
%
% Author: I. D Flintoft
% Date: 19/08/2016
% Version: 1.0.0

  % Get base name of solver installation.
  baseName = fileparts( which( 'pwbTests' ) );
  
  % Test folder.
  testDir = [ baseName , '/tests' ];
  addpath( testDir );
   
  % Any file in the test directory with name starting pwbsTest is a test.
  testList = dir( [ testDir , '/pwbTest*.m'] );

  % Run tests
  for testIdx = 1:length( testList )
    [ ~ , testName , suffix , ~ ] = fileparts( testList(testIdx).name );
    fprintf( 'running test: %s ... ' ,  testName );
    isPass(testIdx) = feval( testName );
    if( isPass(testIdx) )
      fprintf( 'pass\n' );
    else
      fprintf( 'fail\n' );
    end % if
  end % for

  fprintf( '\npassed %d out of %d tests\n\n' , sum( isPass == true ) , length( testList ) );
  
  rmpath( testDir );

end % function