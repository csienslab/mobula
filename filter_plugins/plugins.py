class FilterModule(object):
    def filters(self):
        return {
            'get_access_addr': self.get_access_addr,
            'get_wireguard_addr': self.get_wireguard_addr,
        }

    def get_access_addr(self, host_id, typ):
        # host_id should be less than 32768
        assert host_id < 32768

        def _gen(value):
            return '10.31.{}.{}/16'.format((value & 0xFF00)>>8, (value & 0xFF))

        if typ == 'gateway':
            return _gen(host_id)
        elif typ == 'host':
            return _gen(host_id | 0x8000)
        else:
            raise Exception()

    def get_wireguard_addr(self, host_id):
        return '10.30.{}.{}/16'.format((host_id & 0xFF00)>>8, (host_id & 0xFF))
