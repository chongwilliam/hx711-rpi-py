from HX711 import SimpleHX711, Rate, Mass, Options, ReadType
import redis
import argparse
import yaml
import sys

if __name__ == '__main__':
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    parser = argparse.ArgumentParser()
    parser.add_argument('--axis', type=str, required=True)
    # parser.add_argument('--axis', type=str, required=True)
    # parser.add_argument('--pin_a', type=str, required=True)
    # parser.add_argument('--pin_b', type=str, required=True)
    # parser.add_argument('--unit', type=int, required=True)
    # parser.add_argunetn('--offset', type=int, required=True)
    args = parser.parse_args()

    if args.axis == 'y':
        param_fname = 'fy_sensor.yaml'
    elif args.axis == 'z':
        param_fname == 'fz_sensor.yaml'
    else:
        sys.exit()

    with open(param_fname, 'r') as yaml_file:
        params = yaml.safe_load(yaml_file)

    # load calibration data
    with open(params['cal_file'], 'r') as file:
        unit = int(file.readline())
        offset = int(file.readline())

    force_str = params['key']
    pin_a = params['pin_a']
    pin_b = params['pin_b']

    with SimpleHX711(pin_a, pin_b, unit, offset, Rate.HZ_80) as hx:
        hx.setUnit(Mass.Unit.G)
        # hx.zero(Options(timedelta(seconds=1), ReadType.Average))
        hx.zero()
        while True:
            r.set(force_str, str(9.81 * float(hx.weight())))

