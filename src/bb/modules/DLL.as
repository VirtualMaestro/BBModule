/**
 * Created by oreva on 29.05.2014.
 */
package bb.modules
{
	internal class DLL
	{
		public var size:int = 0;

		public var head:Node;
		public var tail:Node;

		/**
		 */
		public function add(p_listenerMethod:Function, p_listenerModule:BBModule, p_senderModuleClass:Class = null):Node
		{
			var node:Node = Node.get(p_listenerMethod, p_listenerModule, p_senderModuleClass);
			node.dll = this;

			if (tail)
			{
				tail.next = node;
				node.prev = tail;
				tail = node;
			}
			else head = tail = node;

			++size;

			return node;
		}

		/**
		 */
		public function unlink(p_node:Node):void
		{
			if (p_node == tail)
			{
				tail = tail.prev;
				if (tail == null) head = null;
				else tail.next = null;
			}
			else if (p_node == head)
			{
				head = head.next;
				if (head == null) tail = null;
				else head.prev = null;
			}
			else
			{
				var prevNode:Node = p_node.prev;
				var nextNode:Node = p_node.next;

				prevNode.next = nextNode;
				nextNode.prev = prevNode;
			}

			p_node.dispose();

			--size;
		}

		/**
		 */
		public function clear():void
		{
			while (tail)
			{
				tail.unlink();
			}
		}
	}
}
