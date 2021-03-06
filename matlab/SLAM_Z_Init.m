function Zobs = SLAM_Z_Init( Zobs, RptFeatureObs, nPoseNew, nPts, inertialDelta, SLAM_Params )
    global PreIntegration_options
    
    %% camera observations (u,v)
    %zidend = 0; 
    zid = 0;
    zrow = 0;
    
    for(fid=1:nPts)% local id
        
        nObs = RptFeatureObs(fid).nObs;
        for(oid=1:nObs)
            tv = RptFeatureObs(fid).obsv(oid).uv';
            zid = zid + 1;
            Zobs.fObs(zid).uv = tv(:);
            Zobs.fObs(zid).row = (1:2) + zrow;
            zrow = zrow + 2;
        end
    end
    
    Zobs.fObs(zid+1:end) = []; % delete unused spaces
    nUV = zid*2; %size(Zobs.fObs(1).uv, 1)

    %%%%%%%%%%%%%%%%%
    
    %% Put IMU data into observation vector z: 
    % Add interated IMU observations
    if(PreIntegration_options.bPerfectIMUdlt == 1)

        inertialDelta = fnCalPerfectIMUdlt_general(X_obj, nPoseNew, nPts, Jd, dtIMU, SLAM_Params); 
    end
    for p = 2 : nPoseNew
        Zobs.intlDelta(p-1).deltaP.val = inertialDelta.dp(:, p);
        Zobs.intlDelta(p-1).deltaP.row = (1:3) + zrow;
        zrow = zrow + 3;

        Zobs.intlDelta(p-1).deltaV.val = inertialDelta.dv(:, p);
        Zobs.intlDelta(p-1).deltaV.row = (1:3) + zrow;
        zrow = zrow + 3;

        Zobs.intlDelta(p-1).deltaPhi.val = inertialDelta.dphi(:, p);
        Zobs.intlDelta(p-1).deltaPhi.row = (1:3) + zrow;
        zrow = zrow + 3;
    end

    %% Continue filling in Zobs with psedu observations related to IMU
    if(PreIntegration_options.bAddZg == 1)
        % Add pseudo observation of g        
        Zobs.g.val = SLAM_Params.g0;
        Zobs.g.row = (1:3) + zrow;
        zrow = zrow + 3;            
    end
    
    if(PreIntegration_options.bAddZau2c == 1)
        % Add pseudo observation of Tu2c
        [alpha, beta, gamma] = fn_ABGFromR(SLAM_Params.Ru2c);
        Zobs.Au2c.val = [alpha; beta; gamma];
        Zobs.Au2c.row = (1:3) + zrow;
        zrow = zrow + 3;
    end
    
    if(PreIntegration_options.bAddZtu2c == 1)
        % Add pseudo observation of Tu2c
        Zobs.Tu2c.val = SLAM_Params.Tu2c;
        Zobs.Tu2c.row = (1:3) + zrow;
        zrow = zrow + 3;
    end

        
    if(PreIntegration_options.bVarBias == 0)

        if(PreIntegration_options.bAddZbf == 1)
            % Add pseudo observation of bf
            Zobs.Bf.val = SLAM_Params.bf0;
            Zobs.Bf.row = (1:3) + zrow;
            zrow = zrow + 3;
        end

        if(PreIntegration_options.bAddZbw == 1)
            % Add pseudo observation of bf
            Zobs.Bw.val = SLAM_Params.bw0;
            Zobs.Bw.row = (1:3) + zrow;
            zrow = zrow + 3;
        end
    else
        
        for(pid=2:(nPoseNew-1))
           Zobs.Bf.iter(pid-1).val = 0; %bfi-bfi1 = 0
           Zobs.Bf.iter(pid-1).row = (1:3) + zrow; zrow = zrow + 3;
        end
           
        for(pid=2:(nPoseNew-1))
           Zobs.Bw.iter(pid-1).val = 0; %bwi-bwi1 = 0
           Zobs.Bw.iter(pid-1).row = (1:3) + zrow; zrow = zrow + 3;
        end
           
    end
    
