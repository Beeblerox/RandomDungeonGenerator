package ;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * Haxe port of Random Dungeon Generator: http://bigbadwofl.me/random-dungeon-generator/
 */
class Dungeon
{
	/**
	 * Default colors for tiles
	 */
	public static var GROUND_COLOR:Int = 0x351330;
	public static var FLOOR_COLOR:Int = 0x64908A;
	public static var WALL_COLOR:Int = 0x424254;
	
	/**
	 * Default values for tile id's of the map
	 */
	public static inline var GROUND_TILE:Int = 0;
	public static inline var FLOOR_TILE:Int = 1;
	public static inline var WALL_TILE:Int = 2;
	
	/**
	 * Just a helper objects. Used for less garbage creation
	 */
	private static var pointA:Point = new Point();
	private static var pointB:Point = new Point();
	
	/**
	 * Two-dimensional array representing dungeon map
	 */
	public var map:Array<Array<Int>>;
	
	/**
	 * The size of the dungeon.
	 * Width = height, but you can easily modify this class make it rectangular
	 */
	public var mapSize(default, null):Int = 64;
	
	/**
	 * Just a helper array holding temp info about rooms in the dungeon
	 */
	private var rooms:Array<Rectangle>;
	
	/**
	 * Minimum number of rooms in the dungeon
	 */
	private var minRooms:Int = 10;
	
	/**
	 * Maximum number of rooms in the dungeon
	 */
	private var maxRooms:Int = 20;
	
	/**
	 * Minimum size of the dungeon's rooms
	 */
	private var minSize:Int = 5;
	
	/**
	 * Maximum size of the dungeon's rooms
	 */
	private var maxSize:Int = 15;
	
	/**
	 * The number of squash iterations to make dungeon more compact.
	 */
	private var squashIterations:Int = 8;
	
	/**
	 * Dungeon constructor. Automatically calls dungeon generation method.
	 * @param	MapSize				The size of the dungeon.
	 * @param	MinRooms			Minimum number of rooms in the dungeon
	 * @param	MaxRooms			Maximum number of rooms in the dungeon
	 * @param	MinSize				Minimum size of the dungeon's rooms
	 * @param	MaxSize				Maximum size of the dungeon's rooms
	 * @param	SquashIterations	The number of squash iterations to make dungeon more compact.
	 */
	public function new(MapSize:Int = 64, MinRooms:Int = 10, MaxRooms:Int = 20, MinSize:Int = 5, MaxSize:Int = 15, SquashIterations:Int = 8) 
	{
		generate(MapSize, MinRooms, MaxRooms, MinSize, MaxSize, SquashIterations);
	}
	
	/**
	 * Dungeon generation method. Read dungeon's map array after calling it
	 * @param	MapSize				The size of the dungeon.
	 * @param	MinRooms			Minimum number of rooms in the dungeon
	 * @param	MaxRooms			Maximum number of rooms in the dungeon
	 * @param	MinSize				Minimum size of the dungeon's rooms
	 * @param	MaxSize				Maximum size of the dungeon's rooms
	 * @param	SquashIterations	The number of squash iterations to make dungeon more compact.
	 */
	public function generate(MapSize:Int = 64, MinRooms:Int = 10, MaxRooms:Int = 20, MinSize:Int = 5, MaxSize:Int = 15, SquashIterations:Int = 8):Void
	{
		mapSize = MapSize;
		minRooms = MinRooms;
		maxRooms = MaxRooms;
		minSize = MinSize;
		maxSize = MaxSize;
		squashIterations = SquashIterations;
		
		map = new Array<Array<Int>>();
		rooms = [];
		
		for (x in 0...mapSize)
		{
			map[x] = new Array<Int>();
			
			for (y in 0...(mapSize))
			{
				map[x][y] = Dungeon.GROUND_TILE;
			}
		}
		
		var roomCount:Int = RandomHelper.getInt(minRooms, maxRooms);
		
		var room:Rectangle;
		while (rooms.length < roomCount)
		{
			room = new Rectangle();
			room.x = RandomHelper.getInt(1, mapSize - maxSize - 1);
			room.y = RandomHelper.getInt(1, mapSize - maxSize - 1);
			room.width = RandomHelper.getInt(minSize, maxSize);
			room.height = RandomHelper.getInt(minSize, maxSize);
			
			if (doesCollide(room))
			{
				continue;
			}
			
			room.width -= 1;
			room.height -= 1;
			rooms.push(room);
		}
		
		squashRooms();
		
		for (i in 0...roomCount)
		{
			var roomA:Rectangle = rooms[i];
			var roomB:Rectangle = findClosestRoom(roomA);
			
			pointA.setTo(	RandomHelper.getInt(roomA.x, roomA.x + roomA.width),
							RandomHelper.getInt(roomA.y, roomA.y + roomA.height));
			
			pointB.setTo(	RandomHelper.getInt(roomB.x, roomB.x + roomB.width),
							RandomHelper.getInt(roomB.y, roomB.y + roomB.height));
			
			while ((Std.int(pointB.x) != Std.int(pointA.x)) || (Std.int(pointB.y) != Std.int(pointA.y)))
			{
				if (pointB.x != pointA.x)
				{
					if (pointB.x > pointA.x) pointB.x -= 1;
                    else pointB.x += 1;
				}
				else if (pointB.y != pointA.y) 
				{
                    if (pointB.y > pointA.y) pointB.y -= 1;
                    else pointB.y += 1;
                }
				
				map[Std.int(pointB.x)][Std.int(pointB.y)] = Dungeon.FLOOR_TILE;
			}
		}
		
		for (i in 0...roomCount) 
		{
            room = rooms[i];
            for (x in Std.int(room.x)...Std.int(room.x + room.width)) 
			{
                for (y in Std.int(room.y)...Std.int(room.y + room.height)) 
				{
                    this.map[x][y] = Dungeon.FLOOR_TILE;
                }
            }
        }
		
        for (x in 0...mapSize) 
		{
            for (y in 0...mapSize) 
			{
                if (map[x][y] == Dungeon.FLOOR_TILE) 
				{
                    for (xx in (x - 1)...(x + 2))
					{
                        for (yy in (y - 1)...(y + 2)) 
						{
                            if (map[xx][yy] == 0) map[xx][yy] = Dungeon.WALL_TILE;
                        }
                    }
                }
            }
        }
	}
	
	private function findClosestRoom(room:Rectangle):Rectangle
	{
		var mid:Point = pointA;
		var checkMid:Point = pointB;
		mid.setTo(room.x + (room.width / 2), room.y + (room.height / 2));
        
        var closest:Rectangle = null;
        var closestDistance:Float = 1000;
		
        for (i in 0...rooms.length) 
		{
            var check:Rectangle = this.rooms[i];
            if (check == room) continue;
            checkMid.setTo(check.x + (check.width / 2), check.y + (check.height / 2));
            
			var dx:Float = mid.x - checkMid.x;
			var dy:Float = mid.y - checkMid.y;
			
            var distance:Float = Math.sqrt(dx * dx + dy * dy);
            if (distance < closestDistance) 
			{
                closestDistance = distance;
                closest = check;
            }
        }
        return closest;
	}
	
	private function squashRooms():Void
	{
		var room:Rectangle;
		var oldPosition:Point = pointA;
		
		for (i in 0...squashIterations) 
		{
            for (j in 0...rooms.length) 
			{
                var room:Rectangle = this.rooms[j];
                while (true) 
				{
					oldPosition.setTo(room.x, room.y);
                    
					if (room.x > 1) room.x -= 1;
                    if (room.y > 1) room.y -= 1;
                    if ((room.x == 1) && (room.y == 1)) break;
                    if (doesCollide(room, j)) 
					{
                        room.x = oldPosition.x;
                        room.y = oldPosition.y;
                        break;
                    }
                }
            }
        }
	}
	
	private function doesCollide(Room:Rectangle, Ignore:Int = -1):Bool
	{
		if (rooms.length == 0) return false;
		
		for (i in 0...(rooms.length)) 
		{
			if (i >= 0 && i == Ignore) continue;
			var check:Rectangle = rooms[i];
			if ((Room.x + Room.width > check.x) && (Room.x < check.x + check.width) && (Room.y + Room.height > check.y) && (Room.y < check.y + check.height)) return true;
        }
		
        return false;
	}
	
	/**
	 * Get one-dimensional array with info about dungeon. Can be used for loading maps in flixel
	 * @return	one-dimensional array with info about generated dungeon
	 */
	public function getFlixelData():Array<Int>
	{
		if (map.length != mapSize)	return null;
		
		var data:Array<Int> = [];
		var i:Int = 0;
		for (x in 0...mapSize)
		{
			for (y in 0...(mapSize))
			{
				data[i++] = map[x][y];
			}
		}
		
		return data;
	}
	
	/**
	 * Get BitmapData object where each pixel represents each tile of the dungeon
	 */
	public function getBitmapData():BitmapData
	{
		if (map.length != mapSize)	return null;
		
		var bitmap:BitmapData = new BitmapData(mapSize, mapSize);
		for (x in 0...mapSize)
		{
			for (y in 0...mapSize)
			{
				var tile:Int = map[x][y];
				var color:Int = 0;
				if (tile == Dungeon.GROUND_TILE)	color = Dungeon.GROUND_COLOR;
				if (tile == Dungeon.FLOOR_TILE)		color = Dungeon.FLOOR_COLOR;
				if (tile == Dungeon.WALL_TILE)		color = Dungeon.WALL_COLOR;
				bitmap.setPixel(x, y, color);
			}
		}
		return bitmap;
	}
}

/**
 * Just a helper class for getting random integer numbers from specified range
 */
class RandomHelper
{
	public static function getInt(low:Float, hight:Float):Int
	{
		return Std.int(Std.int(Math.random() * (hight - low)) + low);
	}
}