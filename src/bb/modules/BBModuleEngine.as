package bb.modules
{
	import bb.signals.BBSignal;

	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.getTimer;

	CONFIG::debug
	{
		import vm.classes.ClassUtil;
		import vm.debug.Assert;
	}

	/**
	 * Engine of module system.
	 */
	public class BBModuleEngine
	{
		/**
		 * You can set fixed time step, value should be greater than 0 - e.g. 30, 60 or some other (e.g. as fps of app).
		 * In that case delta time will always the same.
		 */
		public var fixedTimeStep:int = 0;

		//
		private var _stage:Stage;

		private var _head:BBModule = null;
		private var _tail:BBModule = null;

		private var _headUpd:BBModule = null;
		private var _tailUpd:BBModule = null;

		private var _registrationList:Vector.<BBModule>;

		/**
		 */
		public function BBModuleEngine(p_stage:Stage = null)
		{
			_stage = p_stage;

			//
			_registrationList = new <BBModule>[];
		}

		/**
		 * Method creates and adds module to system.
		 * As parameter set class of module.
		 * (If class is not inheritor of BBModule class then generates exception - if debug version of lib).
		 */
		public function addModule(moduleClass:Class):BBModule
		{
			CONFIG::debug
			{
				Assert.isTrue(ClassUtil.isSubclassOf(moduleClass, BBModule), "ERROR! bb.modules.BBModuleEngine.addModule: given moduleClass is not an inheritor of BBModule class!");
				Assert.isTrue(isModuleAlreadyInSystem(moduleClass) == false, "ERROR! bb.modules.BBModuleEngine.addModule: given moduleClass already in system!");
			}

			var module:BBModule = new moduleClass();
			_registrationList.push(module);

			checkForOnOffRegisterModulesLoop();

			return module;
		}

		/**
		 * Returns instance of module by given module class name.
		 * If such instance is not in a system returns null.
		 */
		public function getModule(moduleClass:Class):BBModule
		{
			var resultModule:BBModule = _head;

			while (resultModule)
			{
				if (resultModule is moduleClass) return resultModule;
				resultModule = resultModule.next;
			}

			return null;
		}

		/**
		 */
		private function registerModulesLoop(event:Event):void
		{
			var numModules:int = _registrationList.length;
			var module:BBModule;

			for (var i:int = 0; i < numModules; i++)
			{
				module = _registrationList[i];
				_registrationList[i] = null;

				module.onDispose.add(removeModuleHandler);
				module.onUpdate.add(updateModuleHandler);
				addToList(module);
				module._engine = this;
			}

			_registrationList.length = 0;

			// send signal onInit for all registered modules
			module = _head;
			while (module)
			{
				module.onInit.dispatch();
				module = module.next;
			}

			// send signal onReadyToUse for all registered modules
			module = _head;
			while (module)
			{
				module.onReadyToUse.dispatch();
				module = module.next;
			}

			//
			checkForOnOffRegisterModulesLoop();
		}

		/**
		 */
		private function removeModuleHandler(signal:BBSignal):void
		{
			var module:BBModule = signal.dispatcher as BBModule;
			if (module.updateEnable) unlinkFromUpdateList(module);
			unlinkFromList(module);
		}

		/**
		 */
		private function updateModuleHandler(signal:BBSignal):void
		{
			var module:BBModule = signal.dispatcher as BBModule;
			if (module.updateEnable) addToUpdateList(module);
			else unlinkFromUpdateList(module);

			//
			checkForOnOffUpdateModulesLoop();
		}

		//
		private var _prevTime:int = 1;

		/**
		 */
		private function updateModulesLoop(event:Event):void
		{
			var currentTime:int = getTimer();
			var deltaTime:int;

			if (_prevTime == 1) deltaTime = _prevTime;
			else
			{
				if (fixedTimeStep > 0) deltaTime = fixedTimeStep;
				else deltaTime = currentTime - _prevTime;
			}

			//
			var module:BBModule = _headUpd;
			var curModule:BBModule;

			while (module)
			{
				curModule = module;
				module = module.next;

				curModule.update(deltaTime);
				if (module && !module._updateEnable) module = module.next;
			}

			//
			_prevTime = currentTime;
		}

		//
		private var _registerLoopOn:Boolean = false;

		/**
		 */
		private function checkForOnOffRegisterModulesLoop():void
		{
			if (_stage == null) return;

			if (_registrationList.length > 0)
			{
				if (!_registerLoopOn) _stage.addEventListener(Event.ENTER_FRAME, registerModulesLoop);
				_registerLoopOn = true;
			}
			else
			{
				if (_registerLoopOn) _stage.removeEventListener(Event.ENTER_FRAME, registerModulesLoop);
				_registerLoopOn = false;
			}
		}

		//
		private var _updateLoopOn:Boolean = false;

		/**
		 */
		private function checkForOnOffUpdateModulesLoop():void
		{
			if (_stage == null) return;

			if (_headUpd)
			{
				if (!_updateLoopOn) _stage.addEventListener(Event.ENTER_FRAME, updateModulesLoop);
				_updateLoopOn = true;
			}
			else
			{
				if (_updateLoopOn) _stage.removeEventListener(Event.ENTER_FRAME, updateModulesLoop);
				_updateLoopOn = false;
			}
		}

		/**
		 */
		public function get stage():Stage
		{
			return _stage;
		}

		/**
		 */
		public function set stage(val:Stage):void
		{
			if ((_stage != null) || (val == null)) return;
			_stage = val;
			checkForOnOffRegisterModulesLoop();
		}

		/**
		 * Adds module to common list.
		 */
		private function addToList(p_module:BBModule):void
		{
			if (_tail)
			{
				_tail.next = p_module;
				p_module.prev = _tail;
				_tail = p_module;
			}
			else _head = _tail = p_module;
		}

		/**
		 * Removes node from common list.
		 */
		private function unlinkFromList(p_module:BBModule):void
		{
			if (p_module == _head)
			{
				_head = _head.next;
				if (_head == null) _tail = null;
				else _head.prev = null;
			}
			else if (p_module == _tail)
			{
				_tail = _tail.prev;
				if (_tail == null) _head = null;
				else _tail.next = null;
			}
			else
			{
				var prevNode:BBModule = p_module.prev;
				var nextNode:BBModule = p_module.next;
				prevNode.next = nextNode;
				nextNode.prev = prevNode;
			}

			p_module.next = null;
			p_module.prev = null;
		}

		/**
		 * Adds module to update list.
		 */
		private function addToUpdateList(p_module:BBModule):void
		{
			if (_tailUpd)
			{
				_tailUpd.nextUpd = p_module;
				p_module.prevUpd = _tailUpd;
				_tailUpd = p_module;
			}
			else _headUpd = _tailUpd = p_module;
		}

		/**
		 * Removes node from update list.
		 */
		private function unlinkFromUpdateList(p_module:BBModule):void
		{
			if (p_module == _headUpd)
			{
				_headUpd = _headUpd.nextUpd;
				if (_headUpd == null) _tailUpd = null;
				else _headUpd.prevUpd = null;
			}
			else if (p_module == _tailUpd)
			{
				_tailUpd = _tailUpd.prevUpd;
				if (_tailUpd == null) _headUpd = null;
				else _tailUpd.nextUpd = null;
			}
			else
			{
				var prevNode:BBModule = p_module.prevUpd;
				var nextNode:BBModule = p_module.nextUpd;
				prevNode.nextUpd = nextNode;
				nextNode.prevUpd = prevNode;
			}

			p_module.nextUpd = null;
			p_module.prevUpd = null;
		}

		CONFIG::debug
		private function isModuleAlreadyInSystem(moduleClass:Class):Boolean
		{
			var module:BBModule = _head;
			while (module)
			{
				if (module is moduleClass) return true;
				module = module.next;
			}

			return false;
		}
	}
}