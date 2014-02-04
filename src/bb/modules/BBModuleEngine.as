package bb.modules
{
	import bb.signals.BBSignal;

	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.Dictionary;
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

		private var _isStats:Boolean = false;
		private var _stats:BBStats;

		private var _modulesTable:Dictionary;

		/**
		 */
		public function BBModuleEngine(p_stage:Stage = null)
		{
			_stage = p_stage;

			//
			_registrationList = new <BBModule>[];
			_modulesTable = new Dictionary();
		}

		/**
		 * Method creates and adds module to system.
		 * As parameter set class of module.
		 * (If class is not inheritor of BBModule class then generates exception - if debug version of lib).
		 *
		 * if 'p_immediately' is true, module added immediately without registration loop.
		 * But be careful, use only in runtime. Be sure that modules which gets current module already in system and initialized.
		 */
		public function addModule(moduleClass:Class, p_immediately:Boolean = false):BBModule
		{
			CONFIG::debug
			{
				Assert.isTrue(ClassUtil.isSubclassOf(moduleClass, BBModule),
				              "ERROR! bb.modules.BBModuleEngine.addModule: given moduleClass is not an inheritor of BBModule class!");
				Assert.isTrue(isModuleExist(moduleClass) == false,
				              "ERROR! bb.modules.BBModuleEngine.addModule: given moduleClass already in system!");
			}

			//
			var module:BBModule = new moduleClass();
			_modulesTable[moduleClass] = module;

			//
			if (p_immediately) addModuleImmediately(module);
			else
			{
				_registrationList.push(module);
				checkForOnOffRegisterModulesLoop();
			}

			return module;
		}

		/**
		 * Adds module immediately without loop registration process.
		 */
		private function addModuleImmediately(p_module:BBModule):void
		{
			addModuleToEngine(p_module);

			p_module.init();
			p_module.readyToUse();
		}

		/**
		 * Returns instance of module by given module class name.
		 * If such instance is not in a system returns null.
		 */
		public function getModule(moduleClass:Class):BBModule
		{
			return _modulesTable[moduleClass];
		}

		/**
		 */
		private function registerModulesLoop(event:Event):void
		{
			var numModules:int = _registrationList.length;
			var registeredList:Vector.<BBModule> = new Vector.<BBModule>(numModules);
			var module:BBModule;

			// add module to engine
			for (var i:int = 0; i < numModules; i++)
			{
				module = _registrationList[i];
				registeredList[i] = module;
				_registrationList[i] = null;

				addModuleToEngine(module);
			}

			_registrationList.length = 0;

			// send signal onInit for all registered modules
			for (i = 0; i < numModules; i++)
			{
				registeredList[i].init();
			}

			// send signal onReadyToUse for all registered modules
			for (i = 0; i < numModules; i++)
			{
				module = registeredList[i];
				if (module.isInitialized) module.readyToUse();
			}

			//
			checkForOnOffRegisterModulesLoop();
		}

		/**
		 * Adds module to engine with all initializations.
		 */
		private function addModuleToEngine(p_module:BBModule):void
		{
			p_module.onDispose.add(removeModuleHandler);
			p_module.onUpdate.add(updateModuleHandler);
			addToList(p_module);
			p_module.i_engine = this;
		}

		/**
		 */
		private function removeModuleHandler(signal:BBSignal):void
		{
			var module:BBModule = signal.dispatcher as BBModule;
			if (module.updateEnable) unlinkFromUpdateList(module);
			unlinkFromList(module);
			removeModuleFromTable(module);
		}

		/**
		 */
		private function removeModuleFromTable(p_module:BBModule):void
		{
			for (var classKey:Object in _modulesTable)
			{
				if (_modulesTable[classKey] == p_module)
				{
					delete _modulesTable[classKey];
					break;
				}
			}
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
			var currentTimeStats:int = currentTime;
			var deltaTime:int;

			if (_prevTime == 1)
			{
				currentTimeStats = 2;
				deltaTime = _prevTime;
			}
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
				module = module.nextUpd;

				curModule.update(deltaTime);
				if (module && !module.i_updateEnable) module = module.nextUpd;
			}

			if (_isStats) _stats.update(_prevTime, currentTimeStats, getTimer() - currentTime);

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

		/**
		 * Check if module exist in engine.
		 * It is doesn't check if module initialized already.
		 * For checking exist and init use method 'isModuleExistAndInit'.
		 */
		final public function isModuleExist(p_moduleClass:Class):Boolean
		{
			return _modulesTable[p_moduleClass] != null;
		}

		/**
		 * Check if module exist and init already.
		 */
		final public function isModuleExistAndInit(p_moduleClass:Class):Boolean
		{
			var module:BBModule = _modulesTable[p_moduleClass];
			return  (module && module.isInitialized);
		}

		/**
		 */
		public function set stats(p_val:Boolean):void
		{
			if (_isStats == p_val) return;
			_isStats = p_val;

			if (_isStats)
			{
				if (_stats == null) _stats = new BBStats();
				stage.addChildAt(_stats, stage.numChildren);
			}
			else
			{
				stage.removeChild(_stats);
			}
		}

		public function get stats():Boolean
		{
			return _isStats;
		}

		/**
		 * Set display style for stats window.
		 */
		public function setStyleStats(p_backgroundColor:uint = 0x000000, p_textColor:uint = 0xffffff):void
		{
			if (_stats) _stats.setStyle(p_backgroundColor, p_textColor);
		}
	}
}