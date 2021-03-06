function [ pwbm ] = pwbsAddAbsorber( pwbm , tag ,  cavityTag , multiplicity , type , parameters )
% pwbsAddAbsorber - Add an Absorber to a PWB model.
%
% [ pwbm ] = pwbsAddAbsorber( pwbm , tag , cavityTag , multiplicity , type , parameters )
%
%% Inputs:
%
% pwbm         - structure, model state 
% tag          - string, absorber name
% cavityTag    - string, name of cavity containing the absorber
% multiplicity - integer scalar, number of (identical) absorbers to add
% type         - string, type of absorber
% parameters   - cell array, type specific parameter list
%
%% Outputs:
%
% pwbm         - structure, model state
%
%
% The supported absorber types are:
%
% type               | parameters
% :------------------|:-------------------------------------------
% 'ACS'              | { area , ACS }
% 'AE'               | { area , AE  }
% 'FileACS'          | { area , fileName }
% 'FileAE'           | { area , fileName }
% 'MetalSurface'     | { area , sigma , mu_r }
% 'DielSurface'      | { area , eps_r , sigma , mu_r }
% 'LaminatedSurface' | { area , thickness , eps_r , sigma , mu_r }
% 'LaminatedSphere'  | { radii , eps_r , sigma , mu_r }
% 'ConvexHomoBody'   | { area , eps_r , sigma , mu_r }
%
% with parameters
%
% parameter   | type          | unit | description
% :-----------|:-------------:|:----:|:------------------------------------------------------
% area        | double scalar | m^2  | area of absorber
% ACS         | double vector | m^2  | average ACS of absorber
% AE          | double vector | -    | average AE of absorber
% fileName    | string        | -    | name of ASCII file containing ACS/AE data
% thicknesses | double vector | m    | thicknesses of each layer of laminated surface
% epcs_r      | complex array | -    | complex relative permittivity layers of sphere/surface
% sigma       | double array  | S/m  | conductivity of layers of sphere/surface
% mu_r        | double array  | -    | relative permeability of layers of sphere/surface
% radii       | double vector | m    | radii of multi-layer sphere
%
%% ACS/AE file format:
%
% # Optional header/comment using initial # character. 
% # Two columns of real data
% # Column 1: Frequency [Hz].
% # Column 2: Total radiation efficiency [-]
% # f [Hz]   AE [-] 
%    ft(1)    AE(1)
%    .....    ......
%    ft(N)    AE(N)
%
% The first frequency, ft(1), must less than or equal to the 
% lowest frequency in the model and the last frequency, ft(N),
% must greater than or equal to the highest frequency in the model.
% The data at the frequencies given in the file are interpolated 
% onto the frequencies requested in th model.
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

  c0 = 299792458;
  
  % Basic checks on validity of parameters.
  validateattributes( tag , { 'char' } , {} , 'pwbsAddAbsorber' , 'tag' , 2 );
  validateattributes( cavityTag , { 'char' } , {} , 'pwbsAddAbsorber' , 'tag' , 3 );
  validateattributes( multiplicity , { 'double' } , { 'positive' } , 'pwbsAddAbsorber' , 'tag' , 4 );
  validateattributes( type , { 'char' } , {} , 'pwbsAddAbsorber' , 'type' , 5 );
  validateattributes( parameters , { 'cell' } , {} , 'pwbsAddAbsorber' , 'parameters' , 6 );

  % Check tag is a valid variable name.
  if( ~isvarname( tag ) )
    error( 'absorber tag %s is not a valid variable name' , tag );  
  end %if

  % Check if tag already used.
  if( mapIsKey( pwbm.absorberMap , tag ) )
    error( 'absorber with tag %s already exists' , tag );
  end % if

  % Check if cavity tag exisits.
  if( ~mapIsKey( pwbm.cavityMap , cavityTag ) )
    error( 'unknown cavity with tag %s' , cavityTag );
  end % if

  if( strcmp( cavityTag , 'EXT' ) )
    error( 'absorber cannot be in "EXT" cavity' );
  end % if
  
  if( rem( multiplicity , 1 ) ~= 0 )
    error( 'multiplicity must be an integer' ); 
  end % if
  
  numFreq = length( pwbm.f );
      
  % Select actons based on absorber type.
  switch( type )
  case 'ACS'
    if( length( parameters ) ~= 2 )
      error( 'ACS absorber type requires two parameters' );
    end % if  
    validateattributes( parameters{1} , { 'double' } , { 'scalar' , 'nonnegative' } , 'parameters{}' , 'area' , 1 );
    validateattributes( parameters{2} , { 'double' } , { 'vector' , 'nonnegative' } , 'parameters{}' , 'ACS' , 2 );
    area = parameters{1};
    ACS = ones( size( pwbm.f ) ) .* parameters{2}(:);
    AE = 4.0 .* ACS ./ area;
  case 'AE'
    if( length( parameters ) ~= 2 )
      error( 'AE absorber type requires two parameters' );
    end % if  
    validateattributes( parameters{1} , { 'double' } , { 'scalar' , 'nonnegative' } , 'parameters{}' , 'area' , 1 );
    validateattributes( parameters{2} , { 'double' } , { 'vector' , 'nonnegative' , '<=' , 1.0 } , 'parameters{}' , 'AE' , 2 );
    area = parameters{1};
    AE = ones( size( pwbm.f ) ) .* parameters{2}(:);
    ACS = 0.25 .* AE .* area;
  case 'FileACS'
    if( length( parameters ) ~= 2 )
      error( 'FileACS absorber type requires two parameters' );
    end % if  
    validateattributes( parameters{1} , { 'double' } , { 'scalar' , 'nonnegative' } , 'parameters{}' , 'area' , 1 );
    validateattributes( parameters{2} , { 'char' } , {} , 'parameters{}' , 'fileName' , 1 );
    area = parameters{1};
    if( ~exist( parameters{2} , 'file' ) )
      error( 'cannot open ACS file %s' , parameters{2} );
    else
      [ data ] = pwbImportAndInterp( pwbm.f , parameters{2} );
      ACS = data(:,1);
    end % if
    AE = 4.0 .* ACS ./ area;
  case 'FileAE'
    if( length( parameters ) ~= 2 )
      error( 'FileAE absorber type requires two parameters' );
    end % if  
    validateattributes( parameters{1} , { 'double' } , { 'scalar' , 'nonnegative' } , 'parameters{}' , 'area' , 1 );
    validateattributes( parameters{2} , { 'char' } , {} , 'parameters{}' , 'fileName' , 1 );
    area = parameters{1};
    if( ~exist( parameters{2} , 'file' ) )
      error( 'cannot open AE file %s' , parameters{2} );
    else
      [ data ] = pwbImportAndInterp( pwbm.f , parameters{2} );
      AE = data(:,1);
    end % if 
    ACS = 0.25 .* AE .* area;
  case 'DielSurface'
    if( length( parameters ) ~= 4 )
      error( 'Dielectric surface absorber type requires four parameters' );
    end % if    
    validateattributes( parameters{1} , { 'double' } , { 'scalar' , 'nonnegative' } , 'parameters{}' , 'area' , 1 );
    area = parameters{1};
    validateattributes( parameters{2} , { 'double' } , { 'vector' } , 'parameters{}' , 'epsc_r' , 2 );
    epsc_r = parameters{2};
    validateattributes( parameters{3} , { 'double' } , { 'real' , 'vector' } , 'parameters{}' , 'sigma' , 3 );
    sigma = parameters{3};
    validateattributes( parameters{4} , { 'double' } , { 'real' , 'vector' } , 'parameters{}' , 'mu_r' , 4 );
    mu_r = parameters{4};
    if( length( epsc_r ) ~= 1 && length( epsc_r ) ~= length( pwbm.f ) )
      error( 'epsc_r must be a scalar or the same size as f' );
    end % if
    if( length( sigma ) ~= 1 && length( sigma ) ~= length( pwbm.f ) )
      error( 'sigma must be a scalar or the same size as f' );
    end % if
    if( length( mu_r ) ~= 1 && length( mu_r ) ~= length( pwbm.f ) )
      error( 'mu_r must be a scalar or the same size as f' );
    end % if
    [ ACS , AE ] = pwbDielectricSurface( pwbm.f , area , epsc_r , sigma , mu_r );
  case 'MetalSurface'
    if( length( parameters ) ~= 3 )
      error( 'Metal surface absorber type requires four parameters' );
    end % if    
    validateattributes( parameters{1} , { 'double' } , { 'scalar' , 'nonnegative' } , 'parameters{}' , 'area' , 1 );
    area = parameters{1};
    validateattributes( parameters{2} , { 'double' } , { 'real' , 'vector' } , 'parameters{}' , 'sigma' , 2 );
    sigma = parameters{2};
    validateattributes( parameters{3} , { 'double' } , { 'real' , 'vector' } , 'parameters{}' , 'mu_r' , 3 );
    mu_r = parameters{3};
    if( length( sigma ) ~= 1 && length( sigma ) ~= length( pwbm.f ) )
      error( 'sigma must be a scalar or the same size as f' );
    end % if
    if( length( mu_r ) ~= 1 && length( mu_r ) ~= length( pwbm.f ) )
      error( 'mu_r must be a scalar or the same size as f' );
    end % if
    [ ACS , AE ] = pwbMetalSurface( pwbm.f , area , sigma , mu_r );
  case 'LaminatedSurface'
    if( length( parameters ) ~= 5 )
      error( 'Dielectric surface absorber type requires five parameters' );
    end % if
    validateattributes( parameters{1} , { 'double' } , { 'scalar' , 'nonnegative' } , 'parameters{}' , 'area' , 1 );
    area = parameters{1};
    %validateattributes( parameters{2} , { 'double' } , { 'vector' } , 'parameters{}' , 'thicknesses' , 3 );
    thicknesses = parameters{2};
    validateattributes( parameters{3} , { 'double' } , {} , 'parameters{}' , 'epsc_r' , 3 );
    epsc_r = parameters{3};
    validateattributes( parameters{4} , { 'double' } , { 'real' } , 'parameters{}' , 'sigma' , 4 );
    sigma = parameters{4};
    validateattributes( parameters{5} , { 'double' } , { 'real' } , 'parameters{}' , 'mu_r' , 5 );
    mu_r = parameters{5};
    numLayer = length( thicknesses ) + 1;
    if( size( epsc_r , 2 ) ~= numLayer || size( sigma , 2 ) ~= numLayer ||  size( mu_r , 2 ) ~= numLayer )
      error( 'epsc_r, sigma and mu_r must have number columns equal to number of layers' );
    end % if
    if( size( epsc_r , 1 ) ~= 1 && size( epsc_r ,1 ) ~= numFreq )
      error( 'epsc_r must be a scalar or the same size as f' );
    end % if
    if( size( sigma , 1 ) ~= 1 && size( sigma , 1 ) ~= numFreq )
      error( 'sigma must be a scalar or the same size as f' );
    end % if
    if( size( mu_r , 1 ) ~= 1 && size( mu_r , 1 ) ~= numFreq )
      error( 'mu_r must be a scalar or the same size as f' );
    end % if
    [ ACS , AE ] = pwbLaminatedSurface( pwbm.f , area , thicknesses , epsc_r , sigma , mu_r , zeros( size( sigma ) )  );
  case 'LaminatedSphere'
    if( length( parameters ) ~= 4 )
      error( 'Laminated sphere absorber type requires four parameters' );
    end % if
    validateattributes( parameters{1} , { 'double' } , { 'vector' , 'positive' } , 'parameters{}' , 'radii' , 1 );
    radii = parameters{1};
    validateattributes( parameters{2} , { 'double' } , {} , 'parameters{}' , 'epsc_r' , 2 );
    epsc_r = parameters{2};
    validateattributes( parameters{3} , { 'double' } , { 'real' } , 'parameters{}' , 'sigma' , 3 );
    sigma = parameters{3};
    validateattributes( parameters{4} , { 'double' } , { 'real' } , 'parameters{}' , 'mu_r' , 4 );
    mu_r = parameters{4};
    numLayer = length( radii );
    if( size( epsc_r , 2 ) ~= numLayer || size( sigma , 2 ) ~= numLayer ||  size( mu_r , 2 ) ~= numLayer )
      error( 'epsc_r, sigma and mu_r must have number columns equal to number of layers' );
    end % if
    if( size( epsc_r , 1 ) ~= 1 && size( epsc_r ,1 ) ~= numFreq )
      error( 'epsc_r must be a scalar or the same size as f' );
    end % if
    if( size( sigma , 1 ) ~= 1 && size( sigma , 1 ) ~= numFreq )
      error( 'sigma must be a scalar or the same size as f' );
    end % if
    if( size( mu_r , 1 ) ~= 1 && size( mu_r , 1 ) ~= numFreq )
      error( 'mu_r must be a scalar or the same size as f' );
    end % if
    area = 4.0 * pi * radii(1)^2;
    [ ACS , AE ] = pwbLaminatedSphere( pwbm.f , radii , epsc_r , sigma , mu_r );  
  case 'ConvexHomoBody'
    if( length( parameters ) ~= 4 )
      error( 'Convex homogeneous body absorber type requires four parameters' );
    end % if    
    validateattributes( parameters{1} , { 'double' } , { 'scalar' , 'nonnegative' } , 'parameters{}' , 'area' , 1 );
    area = parameters{1};
    validateattributes( parameters{2} , { 'double' } , { 'vector' } , 'parameters{}' , 'epsc_r' , 2 );
    epsc_r = parameters{2};
    validateattributes( parameters{3} , { 'double' } , { 'real' , 'vector' } , 'parameters{}' , 'sigma' , 3 );
    sigma = parameters{3};
    validateattributes( parameters{4} , { 'double' } , { 'real' , 'vector' } , 'parameters{}' , 'mu_r' , 4 );
    mu_r = parameters{4};
    if( length( epsc_r ) ~= 1 && length( epsc_r ) ~= length( pwbm.f ) )
      error( 'epsc_r must be a scalar or the same size as f' );
    end % if
    if( length( sigma ) ~= 1 && length( sigma ) ~= length( pwbm.f ) )
      error( 'sigma must be a scalar or the same size as f' );
    end % if
    if( length( mu_r ) ~= 1 && length( mu_r ) ~= length( pwbm.f ) )
      error( 'mu_r must be a scalar or the same size as f' );
    end % if
    radius = sqrt( area / 4.0 / pi );
    [ ACS , AE ] = pwbSphere( pwbm.f , radius , epsc_r , sigma , mu_r );
  otherwise
    error( 'unknown absorber type' , type );
  end % switch

  % Change state.
  pwbm.state = 'init';
  
  % Factor in  multiplicity.
  ACS = ACS .* multiplicity;
  
  % Set attributes.
  pwbm.numAbsorbers = pwbm.numAbsorbers + 1;
  pwbm.absorberMap = mapSet( pwbm.absorberMap , tag , pwbm.numAbsorbers );
  pwbm.absorbers(pwbm.numAbsorbers).tag = tag;
  pwbm.absorbers(pwbm.numAbsorbers).type = type;
  pwbm.absorbers(pwbm.numAbsorbers).multiplicity = multiplicity;
  pwbm.absorbers(pwbm.numAbsorbers).area = area;
  pwbm.absorbers(pwbm.numAbsorbers).parameters = parameters;
  pwbm.absorbers(pwbm.numAbsorbers).ACS = ACS;
  pwbm.absorbers(pwbm.numAbsorbers).AE = AE;
  pwbm.absorbers(pwbm.numAbsorbers).cavityIdx = mapGet( pwbm.cavityMap , cavityTag );
  volume = pwbm.cavities(pwbm.absorbers(pwbm.numAbsorbers).cavityIdx).volume;
  [ Q , decayRate , timeConst ] = pwbEnergyParamsFromCCS( pwbm.f , ACS , volume );
  pwbm.absorbers(pwbm.numAbsorbers).Q = Q;
  pwbm.absorbers(pwbm.numAbsorbers).decayRate = decayRate;     
  pwbm.absorbers(pwbm.numAbsorbers).timeConst = timeConst;
    
  % These attributes are set in the solution phase.
  pwbm.absorbers(pwbm.numAbsorbers).absorbedPower = [];
  
  % Add to edges list.
  pwbm.edges{end+1,1} = cavityTag;  
  pwbm.edges{end,2} = 'REF';
  pwbm.edges{end,3} = tag;
  pwbm.edges{end,4} = 'Absorber';

end % function
