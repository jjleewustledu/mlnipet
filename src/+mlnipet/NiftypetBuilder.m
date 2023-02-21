classdef NiftypetBuilder < handle
    %% line1
    %  line2
    %  
    %  Created 07-Sep-2022 00:26:38 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
    %  Developed on Matlab 9.12.0.2039608 (R2022a) Update 5 for MACI64.  Copyright 2022 John J. Lee.
    
    methods
        function this = call(this, varargin)
        end
        
        function this = NiftypetBuilder(varargin)
            %% NIFTYPETBUILDER 
            %  Args:
            %      arg1 (its_class): Description of arg1.
            
            ip = inputParser;
            addParameter(ip, "arg1", [], @(x) true)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
