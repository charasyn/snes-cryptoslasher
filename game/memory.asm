scope mem {
    ///////////////////////////////////////////
    // Direct Page
    ///////////////////////////////////////////
    StartVariables(0)
    Variable(Tmp,0x20)
    EndVariables()

    // object processing
    scope ObjTmp {
        StartVariables(Tmp)
        Variable(CurrentIndex,1)
        Variable(ObjType,1)
        Variable(ObjX,2)
        Variable(ObjY,2)
        Variable(OAMNum,2)
        Variable(ObjW,1)
        Variable(ObjH,1)
        Variable(ObjState,1)
        Variable(Tmp,0x15)
        EndVariables()
    }
    
    scope Objects {
        StartVariables($20)
        Variable(X, 2 * consts.NumObjects)
        Variable(Y, 2 * consts.NumObjects)
        Variable(VX, 1 * consts.NumObjects)
        Variable(VY, 1 * consts.NumObjects)
        Variable(Type, 1 * consts.NumObjects)
        Variable(State, 1 * consts.NumObjects)
        EndVariables()
    }

    constant ProfilerCount($f0)
    constant LagFrames($f4)
    constant FrameCount($ff)

    ///////////////////////////////////////////
    // Short ptr
    ///////////////////////////////////////////
    // This is used as a word!! It's okay because MainLoopRunning comes after it
    //   and it's only used as a word after the main processing loop is done
    constant NMIHappened($0100)
    constant MainLoopRunning($0101)
    constant OAMBuffer($0200)
    constant OAMBufferHighComp($0400)
    constant OAMBufferHigh($0420)

    ///////////////////////////////////////////
    // Long ptr
    ///////////////////////////////////////////
    constant GfxOutBuf($7e2000)
}