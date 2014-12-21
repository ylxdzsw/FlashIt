@flashit = () ->
	#status variables
	Stack = []
	end = no

	#operation functions
	init = (code,library) ->
		end = no
		Stack = []
		push_stack code, library, -> end = yes

	next = (callback) ->
		callback = callback ? (x)->console.log x
		mission = Stack.pop()
		if is_atom mission.closure.code
			obj = translate_atom mission.closure.code, mission.closure.env
			mission.callback(obj)
		else
			slist = parse_code mission.closure.code
			if slist[0] is 'lambda'
				arglist = parse_code slist[1]
				for i in arglist
					if not is_atom i
						throw new Error("in valiad argument name #{i}")
				mission.callback 
					type: 'closure',
					arg: arglist,
					code: slist[2],
					env: copy_env mission.closure.env
			else if is_atom slist[0]
				obj = translate_atom slist[0], mission.closure.env
				if obj.type is 'function'
					if slist.length is 1
						mission.callback obj.fun()
					else
						counts = 0
						args = []
						for i in slist[1..]
							counts += 1
							push_stack i,copy_env(mission.closure.env),(x)->
								args.unshift x
								if counts is 1
									mission.callback obj.fun(args)
								else
									counts -= 1
				else if obj.type is 'closure'
					if slist.length is 1
						push_stack obj.code,copy_env(obj.env),mission.callback
					else
						counts = 0
						args = []
						for i in slist[1..]
							counts += 1
							push_stack i,copy_env(mission.closure.env),(x)->
								args.unshift x
								if counts is 1
									push_stack obj.code,extend_env(obj.env,obj.arg,args),mission.callback
								else
									counts -= 1
				else
					throw new Error("#{obj.type} is not a function")
			else
				push_stack slist[0],copy_env(mission.closure.env),(obj)->
					if obj.type is 'function'
						if slist.length is 1
							mission.callback obj.fun()
						else
							counts = 0
							args = []
							for i in slist[1..]
								counts += 1
								push_stack i,copy_env(mission.closure.env),(x)->
									args.unshift x
									if counts is 1
										mission.callback obj.fun(args)
									else
										counts -= 1
					else if obj.type is 'closure'
						if slist.length is 1
							push_stack obj.code,copy_env(obj.env),mission.callback
						else
							counts = 0
							args = []
							for i in slist[1..]
								counts += 1
								push_stack i,copy_env(mission.closure.env),(x)->
									args.unshift x
									if counts is 1
										push_stack obj.code,extend_env(obj.env,obj.arg,args),mission.callback
									else
										counts -= 1
					else
						throw new Error("#{obj.type} is not a function")
		callback()

		
	hasNext = () ->
		not end

	#tool functions
	push_stack = (code,env,callback) ->
		Stack.push
			closure:
				type: 'closure'
				code: code
				env: env
			callback: callback

	parse_code = (code) ->
		parenthesis = counter()
		finalAns = []
		codetxt = ""
		codeToBeParse = code.trim().split('')
		if codeToBeParse.shift() isnt '('
			throw new Error("Not a valid expression that start with '('")
		for i in codeToBeParse
			if i is '('
				codetxt += i
				parenthesis.inc()
				continue
			if parenthesis.get() > 0
				codetxt += i
				if i is ')'
					if parenthesis.get() is 1
						finalAns.push codetxt
						codetxt = ""
					parenthesis.dec()
				continue
			if i in [' ','\n','\t']
				if codetxt isnt ""
					finalAns.push codetxt
					codetxt = ""
				continue
			if i isnt ')'
				codetxt += i
			else
				finalAns.push codetxt if codetxt isnt ""
		if parenthesis.get() isnt 0
			throw new Error("parenthesis not matched!\nError code:" + code.trim())
		return finalAns

	copy_env = (x) ->
		y = {}
		y[k] = v for k, v of x
		return y

	extend_env = (env,key,value) ->
		x = copy_env env
		if not value.length? or value.length isnt key.length
			throw new Error("unmatchde arg length")
		else
			for i in [0...key.length]
				x[key[i]] = value[i]
		return x
				
	translate_atom = (code,env) ->
		codeToBeTranslate = code.trim()
		if codeToBeTranslate is '#f'
			return {type:'bool',value:false}
		if not isNaN Number(codeToBeTranslate)
			return {type:'number',value:Number codeToBeTranslate}
		if env[codeToBeTranslate]?
			return env[codeToBeTranslate]
		{type:'undefined'}

	is_atom = (code) ->
		x = code.trim().split('')
		' ' not in x and '(' not in x

	counter = (x) ->
		counts = x ? 0
		{
			inc : () ->
				counts += 1
			dec : () ->
				if counts <= 0
					throw new Error("decreased a counter less than zero")
				counts -= 1
			reset : () ->
				counts = 0
			get : () ->
				counts
		}

	#returns
	{
		init: init,
		next: next,
		hasNext: hasNext
	}

