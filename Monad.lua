Monad = {}

Monad.Monad = {}
Monad.Monad.__index = Monad.Monad

function Monad.Monad:bind(f)
    error("bind not implemented")
end

function Monad.Monad:return_(value)
    error("return not implemented")
end

function Monad.Monad:map(f)
    return self:bind(function(x)
        return self:return_(f(x))
    end)
end

Monad.Maybe = {}
Monad.Maybe.__index = Monad.Maybe
setmetatable(Monad.Maybe, { __index = Monad.Monad })

function Monad.Maybe.just(value)
    return setmetatable({ value = value, isNothing = false }, Monad.Maybe)
end

function Monad.Maybe.nothing()
    return setmetatable({ isNothing = true }, Monad.Maybe)
end

function Monad.Maybe:bind(f)
    if self.isNothing then
        return Monad.Maybe.nothing()
    else
        return f(self.value)
    end
end

function Monad.Maybe:return_(value)
    return Monad.Maybe.just(value)
end

Monad.Result = {}
Monad.Result.__index = Monad.Result
setmetatable(Monad.Result, { __index = Monad.Monad })

function Monad.Result.ok(value)
    return setmetatable({ value = value, isError = false }, Monad.Result)
end

function Monad.Result.err(err)
    return setmetatable({ error = err, isError = true }, Monad.Result)
end

function Monad.Result:bind(f)
    if self.isError then
        return Monad.Result.err(self.error)
    else
        return f(self.value)
    end
end

function Monad.Result:return_(value)
    return Monad.Result.ok(value)
end

function Monad.Result:mapError(f)
    if self.isError then
        return Monad.Result.err(f(self.error))
    else
        return self
    end
end

function Monad.Result.fromMaybe(maybe, errMsg)
    if maybe.isNothing then
        return Monad.Result.err(errMsg)
    else
        return Monad.Result.ok(maybe.value)
    end
end

function Monad.Result:toMaybe()
    if self.isError then
        return Monad.Maybe.nothing()
    else
        return Monad.Maybe.just(self.value)
    end
end

function Monad.Result.fromPair(value, err)
    if err then
        return Monad.Result.err(err)
    else
        return Monad.Result.ok(value)
    end
end

function Monad.F(f)
    return setmetatable({ fn = f }, {
        __concat = function(a, b)
            return Monad.F(function(...)
                return a.fn(b.fn(...))
            end)
        end,
        __call = function(a, ...)
            return a.fn(...)
        end
    })
end

function Monad.K(f)
    return setmetatable({ fn = f }, {
        __concat = function(a, b)
            return Monad.K(function(...)
                return a.fn(...):bind(b.fn)
            end)
        end,
        __call = function(a, ...)
            return a.fn(...)
        end
    })
end
