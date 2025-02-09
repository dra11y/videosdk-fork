import 'dart:math';

int min = 0;
int max = 10000000;

get randomNumber => min + (Random().nextInt(max - min));
