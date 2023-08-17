from HX711 import SimpleHX711, Rate

with SimpleHX711(26, 19, -370, -367471, Rate.HZ_80) as hx:
    while True:
        print(hx.weight())
