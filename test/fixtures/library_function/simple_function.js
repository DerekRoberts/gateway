this.sum = function(values) {
  result = 0;
  values.forEach(function(value) {
    result += value;
  });
  return result;
}