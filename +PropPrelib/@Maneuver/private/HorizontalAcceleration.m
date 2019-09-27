function [PI, stats] = HorizontalAcceleration(varargin)
    [beta, WLto, TLto, alt, M1, M2, TR, CDR, AB, Intervals] = parsevars(varargin);
    import PropPrelib.* 
    
    %Loop Prep
    PI = 1;
    Mr = linspace(M1, M2, Intervals+1);
    stats.Alpha = 0;                      
    stats.AB = 0;
    stats.TFSC = 0;
    stats.Beta_1 = beta;
    
    %This stays the same every iteration, only calculate it once
    [~, a, P, ~, theta, delta] = atmos(alt);
    stats.Theta = theta;
    stats.Delta = delta;
    for i = 1:Intervals    
        M = [Mr(i), Mr(i+1)];
        [theta_0, delta_0] = adjust_atmos(theta, delta, M);
        q = dynamic_pressure(P, M);
        [K1, CD0, K2] = drag_constants(M);

        CL = beta./q.*WLto;
        CD = K1.*CL.^2 + K2.*CL + CD0;
        CDdCL = (CD+CDR)./CL;

        alpha = thrustLapse('theta_0', theta_0,...
                            'delta_0', delta_0,...
                            'TR', TR,...
                            'AB', AB);   

        tfsc_m = mean(tfsc('theta', theta,...
                           'M0'   , M,...
                           'AB'   , AB));

        V = a*M;
        V1 = a*M(1);
        V2 = a*M(2);
        V = mean(V);

        dZe = (V2^2-V1^2)/(2*g0);
        u = mean(CDdCL.*(beta./alpha)*(1./TLto));

        PI = exp(-tfsc_m/(V*(1-u))*dZe);

        stats.Alpha = stats.Alpha + (mean(alpha) - stats.Alpha)/i; %Averaging Alpha                      
        stats.AB = max([stats.AB, AB]); %Important AB is max
        stats.TFSC = stats.TFSC + (tfsc_m - stats.TFSC)/i; %Averaging TFSC 
    end
    stats.Beta_2 = stats.Beta_1 * PI;
    stats.PI = PI;
end

function [beta, WLto, TLto, alt, M1, M2, TR, CDR, AB, Intervals] = parsevars(vars)
import PropPrelib.*
persistent p
if isempty(p)
    p = ArgParser;
    addParameter(p, 'beta', RequiredArg, @isnumeric);
    addParameter(p, 'WLto', RequiredArg, @isnumeric);
    addParameter(p, 'TLto', RequiredArg, @isnumeric);
    addParameter(p, 'TR'  , RequiredArg, @isnumeric);
    addParameter(p, 'alt' , RequiredArg, @isnumeric);
    addParameter(p, 'M1'  , RequiredArg, @isnumeric);
    addParameter(p, 'M2'  , RequiredArg, @isnumeric);
    addParameter(p, 'AB'  , RequiredArg, @isnumeric);
    addParameter(p, 'CDR' , 0, @isnumeric);
    addParameter(p, 'Intervals', 5, @(x)isnumeric(x)&&isscalar(x));
end

try
    arg = parse(p, vars{:});
catch ME
    throwAsCaller(ME)
end   

beta = arg.beta;
WLto = arg.WLto;
TLto = arg.TLto;
alt = arg.alt;
M1 = arg.M1;
M2 = arg.M2;
TR = arg.TR;
CDR = arg.CDR;
AB = arg.AB;
Intervals = arg.Intervals;
end