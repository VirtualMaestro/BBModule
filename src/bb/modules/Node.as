/**
 * Created by oreva on 29.05.2014.
 */
package bb.modules
{
	internal class Node
	{
		public var dll:DLL;
		public var next:Node;
		public var prev:Node;

		public var listener:Function;
		public var listenerModule:BBModule;
		public var senderModuleClass:Class;

		/**
		 */
		public function unlink():void
		{
			if (dll) dll.unlink(this);
		}

		/**
		 */
		public function dispose():void
		{
			dll = null;
			next = prev = null;
			listener = null;
			listenerModule = null;
			senderModuleClass = null;

			put(this);
		}

		// pooling
		static private var _pool:Vector.<Node> = new <Node>[];
		static private var _size:int = 0;

		/**
		 */
		static public function get(p_listener:Function, p_module:BBModule, p_senderModuleClass:Class = null):Node
		{
			var node:Node;

			if (_size > 0)
			{
				node = _pool[--_size];
				_pool[_size] = null;
			}
			else node = new Node();

			node.listener = p_listener;
			node.listenerModule = p_module;
			node.senderModuleClass = p_senderModuleClass;

			return node;
		}

		/**
		 */
		static private function put(p_node:Node):void
		{
			_pool[_size++] = p_node;
		}

		/**
		 */
		static public function rid():void
		{
			for (var i:int = 0; i < _size; i++)
			{
				_pool[i] = null;
			}

			_pool.length = 0;
		}
	}
}
