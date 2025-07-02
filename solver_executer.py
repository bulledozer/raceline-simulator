import numpy as np

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
from src.solver import *
from src.car import *

track_points = []
N = 0

with open(PARAMS['road_dir'], 'r') as f:
    L = f.readlines()
    N = len(L)
    for l in L:
        l1 = l.removesuffix('\n').split(',')
        track_points.append((float(l1[0]), float(l1[1])))

spl = Road(N, track_points, PARAMS['width'], True)
POINTS = spl.compute_points2(PARAMS['n_sectors'], 2)

TIMES = []

sol = Solver(POINTS, PARAMS['scale'], PARAMS['n_sectors'], PARAMS['vmax'], 0.0001)
sol_points = sol.solve(PARAMS['n_iter'], TIMES, False)

for p in sol_points:
    print(str(p[0]) + "," + str(p[1]))

R = 1000
car = Car(5,-7,1500,9.81)
v,s = car.compute_velocity_profile(sol_points, 1, R)

print('speeds')
for i in range(R):
    print(v[i], ",", s[i])


