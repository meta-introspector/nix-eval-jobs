#pragma once

#include <iostream>
#include <mutex>
#include <utility>
struct OutputStreamLock {
  private:
    std::mutex mutex;
    std::ostream *stream;

    struct LockedOutputStream {
      public:
        std::unique_lock<std::mutex> lock;
        std::ostream *stream;
        LockedOutputStream(std::mutex &mutex, std::ostream *stream)
            : lock(mutex), stream(stream) {}
        LockedOutputStream(const LockedOutputStream &) = delete;
        LockedOutputStream(LockedOutputStream &&other) noexcept
            : lock(std::move(other.lock)), stream(other.stream) {}
        auto operator=(const LockedOutputStream &)
            -> LockedOutputStream & = delete;
        auto operator=(LockedOutputStream &&) -> LockedOutputStream & = delete;

        template <class T>
        auto operator<<(const T &value) && -> LockedOutputStream {
            // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-array-to-pointer-decay)
            *stream << value;
            return std::move(*this);
        }

        ~LockedOutputStream() {
            if (lock) {
                *stream << std::flush;
            }
        }
    };

  public:
    explicit OutputStreamLock(std::ostream &stream) : stream(&stream) {}

    auto lock() -> LockedOutputStream { return {mutex, stream}; }
};

auto getCoutLock() -> OutputStreamLock &;