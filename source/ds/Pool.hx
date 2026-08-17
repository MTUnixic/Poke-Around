package ds;

import flixel.FlxG;

//pools unique items together. Technically a set but called it Pool because I made it let you randomly pool items from it.
class Pool<T> {
  var size(get,never):Int;

	var data:Array<T> = [];
	var weights:Array<Float> = [];

  public function new(){}

  inline function get_size()
    return data.length;

  public inline function clear(){
    data.resize(0);
    weights.resize(0);
  }

  //returns a shallow copy of `this` pool. As with arrays, the elements are copied and maintain their identity.
  public function copy(){
    var n = new Pool<T>();
    @:privateAccess n.data = data.copy();
    @:privateAccess n.weights = weights.copy();
    return n;
  }

	public function add(item:T, weight:Float = 1) {
		if (has(item))
			return;
		data.push(item);
		weights.push(weight);
	}

	public inline function has(item:T) {
		return data.indexOf(item) >= 0;
	}

	public function remove(item:T) {
    var index = data.indexOf(item);
		if (index < 0)
			return;
    data.splice(index,1);
    weights.splice(index,1);
	}

	public inline function get():T {
		return FlxG.random.getObject(data, weights);
	}

  public inline function getIndex():Int{
    return FlxG.random.weightedPick(weights);
  }

  public function getWithWeight():{item:T,weight:Float}{
    var i = getIndex();
    return {item:data[i],weight:weights[i]};
  }

  public function getMultiple(amount:Int,noRepeats=true,allowLooping=true):Array<T>{
    if (!noRepeats)
      return [for (_ in 0...amount) get()];

    var tempdata = data.copy();
    var tempweights = weights.copy();

    var gottenItems:Array<T> = [];
    for (i in 0...amount){
      if (tempdata.length == 0){
        if (!allowLooping)
          break;
        tempdata = data.copy();
        tempweights = weights.copy();
      }
      var index = FlxG.random.weightedPick(tempweights);
      var item = tempdata[index];

      tempdata.splice(index,1);
      tempweights.splice(index,1);
      
      gottenItems.push(item);
    }
    return gottenItems;
  }
}
