#pragma once

#include <nix/flake/flake.hh>
#include <nix/util/args/root.hh>
#include <nix/cmd/common-eval-args.hh>
#include <cstddef>
#include <nix/main/common-args.hh>
#include <nix/util/types.hh>
#include <string>

class MyArgs : virtual public nix::MixEvalArgs,
               virtual public nix::MixCommonArgs,
               virtual public nix::RootArgs {
  public:
    virtual ~MyArgs() = default;
    std::string releaseExpr;
    std::string applyExpr;
    nix::Path gcRootsDir;
    bool flake = false;
    bool fromArgs = false;
    bool meta = false;
    bool showTrace = false;
    bool impure = false;
    bool forceRecurse = false;
    bool checkCacheStatus = false;
    bool showInputDrvs = false;
    bool constituents = false;
    size_t nrWorkers = 1;
    size_t maxMemorySize = 4096;

    // usually in MixFlakeOptions
    nix::flake::LockFlags lockFlags = {.updateLockFile = false,
                                       .writeLockFile = false,
                                       .useRegistries = false,
                                       .allowUnlocked = false};
    MyArgs();
    MyArgs(MyArgs &&) = delete;
    auto operator=(const MyArgs &) -> MyArgs & = default;
    auto operator=(MyArgs &&) -> MyArgs & = delete;
    MyArgs(const MyArgs &) = delete;

    void parseArgs(char **argv, int argc);
};
