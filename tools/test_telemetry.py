#!/usr/bin/env python3
from capture_telemetry import FrameParser, decode_frame


def make_frame(sequence, reference, measured, duty, integral, flags):
    data = bytearray(b'\xa5\x5a')
    data += sequence.to_bytes(2, 'little')
    data += reference.to_bytes(2, 'little')
    data += measured.to_bytes(2, 'little')
    data += duty.to_bytes(2, 'little')
    data += integral.to_bytes(4, 'little', signed=True)
    data.append(flags)
    checksum = 0
    for value in data:
        checksum ^= value
    data.append(checksum)
    return bytes(data)


frame = make_frame(0x1234, 512, 227, 1234, -55, 5)
decoded = decode_frame(frame)
assert (decoded.sequence, decoded.reference, decoded.measured, decoded.duty,
        decoded.integral, decoded.flags) == (0x1234, 512, 227, 1234, -55, 5)

parser = FrameParser()
assert parser.feed(b'noise' + frame[:7]) == []
items = parser.feed(frame[7:] + frame)
assert len(items) == 2 and items[0] == decoded and items[1] == decoded

damaged = bytearray(frame)
damaged[8] ^= 1
assert FrameParser().feed(bytes(damaged)) == []
print('TEST PASS telemetry Python decoder, resynchronization, checksum')
