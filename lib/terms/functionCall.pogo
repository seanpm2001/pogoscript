codegenUtils = require './codegenUtils'
_ = require 'underscore'
asyncControl = require '../asyncControl'

module.exports (terms) =
    functionCallTerm = terms.term {
        constructor (
          fun
          args
          async: false
          passThisToApply: false
          originallyAsync: false
          asyncCallbackArgument: nil
        ) =
          self.isFunctionCall = true

          self.function = fun
          self.functionArguments = terms.argumentUtils.positionalArguments(args)
          self.optionalArguments = terms.argumentUtils.optionalArguments(args)
          self.passThisToApply = passThisToApply
          self.isAsync = async
          self.originallyAsync = originallyAsync
          self.asyncCallbackArgument = asyncCallbackArgument

        hasSplatArguments () =
          _.any (self.functionArguments) @(arg)
            arg.isSplat
      
        generate (scope) =
            self.generateIntoBuffer @(buffer)
              buffer.write (self.function.generateFunction (scope))

              args = codegenUtils.concatArgs (
                self.functionArguments
                optionalArgs: self.optionalArguments
                asyncCallbackArg: self.asyncCallbackArgument
                terms: terms
              )

              splattedArguments = self.cg.splatArguments (args)
          
              if (splattedArguments && self.function.isIndexer)
                buffer.write ('.apply(')
                buffer.write (self.function.object.generate (scope))
                buffer.write (',')
                buffer.write (splattedArguments.generate (scope))
                buffer.write (')')
              else if (splattedArguments)
                buffer.write ('.apply(')

                if (self.passThisToApply)
                  buffer.write ('this')
                else
                  buffer.write ('null')

                buffer.write (',')
                buffer.write (splattedArguments.generate (scope))
                buffer.write (')')
              else
                buffer.write ('(')
                codegenUtils.writeToBufferWithDelimiter (args, ',', buffer, scope)
                buffer.write (')')
    }

    functionCall (
      fun
      args
      async: false
      passThisToApply: false
      originallyAsync: false
      asyncCallbackArgument: nil
      couldBeMacro: true
      future: false
      promisify: false
    ) =
      if (async)
        asyncResult = terms.asyncResult ()

        return (
          terms.subStatements [
            terms.definition (
              asyncResult
              functionCallTerm (
                fun
                args
                passThisToApply: passThisToApply
                originallyAsync: true
                asyncCallbackArgument: asyncCallbackArgument
              )
              async: true
            )
            asyncResult
          ]
        )
      else if (future)
        futureFunction =
          terms.moduleConstants.define ['future'] as (
            terms.javascript (asyncControl.future.toString ())
          )

        callback = terms.generatedVariable ['callback']

        return (
          terms.functionCall (
            futureFunction
            [
              terms.closure (
                [callback]
                terms.statements [
                  terms.functionCall (
                    fun
                    args
                    passThisToApply: passThisToApply
                    originallyAsync: true
                    asyncCallbackArgument: callback
                    couldBeMacro: couldBeMacro
                  )
                ]
              )
            ]
          )
        )
      else if (@not promisify @and [a <- args, a.isCallback, a].length > 0)
        @return terms.promisify (
          terms.functionCall (
             fun
             args
             async: false
             passThisToApply: false
             originallyAsync: false
             asyncCallbackArgument: nil
             couldBeMacro: true
             future: false
             promisify: true
          )
        )
      else if (fun.variable @and couldBeMacro)
        name = fun.variable
        macro = terms.macros.findMacro (name)
        funCall = functionCallTerm (fun, args)

        if (macro)
          return (macro (funCall, name, args))

      functionCallTerm (
        fun
        args
        passThisToApply: passThisToApply
        originallyAsync: originallyAsync
        asyncCallbackArgument: asyncCallbackArgument
      )
