import numpy as np
import pandas as pd

PARAMS = {}
with open("C:\\Users\\theem\\Documents\\programs\\raceline-simulator\\solver_params.txt", 'r') as f:
    lines = f.readlines()
    PARAMS['solver_dir'] = lines[0].replace("/", "\\").removesuffix('\n')
    PARAMS['road_dir'] = lines[1].replace("/", "\\").removesuffix('\n')
    PARAMS['width'] = float(lines[2])
    PARAMS['n_sectors'] = int(lines[3])
    PARAMS['vmax'] = float(lines[4])
    PARAMS['n_iter'] = int(lines[5])
    PARAMS['scale'] = float(lines[6])
    PARAMS['save_dir'] = lines[7].replace("/", "\\").removesuffix('\n')

import sys

sys.path.insert(1,PARAMS['solver_dir'])


from src.road import *
from mainOpti import *
from src.car import *

try:
    track_points = pd.read_csv(PARAMS['road_dir']).values[:,:2]
    N = track_points.shape[0]

    spl = Road(N, track_points, PARAMS['width'], True)
    POINTS = spl.compute_points2(PARAMS['n_sectors'], 2)


    #gradient_descent(curve_state,100,TIMES,time_from_state, POINTS)

    def get_sol_points(timef):
        curve_state = [0.5]*(PARAMS['n_sectors'])

        TIMES = [0.0]

        min_state = curve_state
        min_time = float('inf')

        for i in range(PARAMS['n_iter']):
            gradient_descent(curve_state, PARAMS['scale'], TIMES, timef, POINTS, 0.0001)

            if TIMES[-1] < min_time:
                min_state = curve_state

        sol_points = points_from_state(min_state, POINTS)
        return sol_points


    sol_time = get_sol_points(time_from_state)
    sol_dist = get_sol_points(dist_from_state)


    for sol in [sol_time, sol_dist]:

        for p in sol:
            print(str(p[0]) + "," + str(p[1]))

        R = 1000
        car = Car(5,-7,1500,9.81)
        v,s = car.compute_velocity_profile(sol, 1, R)

        print('speeds')
        for i in range(R):
            print(v[i], ",", s[i])

        print('|')
except Exception as e:
    print(e)