# -*- coding: utf-8 -*-
import os
from ipaddress import ip_network
from datetime import datetime

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.dialects.postgresql import INET, CIDR, MACADDR
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, ForeignKey, UniqueConstraint, Table


ipam_db_url = os.environ.get("IPAM_DATABASE")
ipam_db_engine = create_engine(ipam_db_url)
ipam_base = declarative_base(ipam_db_engine)
ipam_db_session = Session(bind=ipam_db_engine)


relate_network_network_type = Table(
    "relate_network_network_type",
    ipam_base.metadata,
    Column("network_id", ForeignKey("network.id"), primary_key=True),
    Column("network_type_id", ForeignKey("network_type.id"), primary_key=True),
    Column("created", DateTime, default=datetime.now(), nullable=False),
    Column("updated", DateTime),
)

relate_vrf_to_device = Table(
    "relate_vrf_to_device",
    ipam_base.metadata,
    Column("vrf_id", ForeignKey("vrf.id"), primary_key=True),
    Column("device_id", ForeignKey("device.id"), primary_key=True),
    Column("created", DateTime, default=datetime.now(), nullable=False),
    Column("updated", DateTime),
)


class IPAddres(ipam_base):
    __tablename__ = "ip_address"
    id = Column(Integer, primary_key=True, nullable=False)              # SERIAL PRIMARY KEY,
    ip_address = Column(INET, nullable=False)                           # INET NOT NULL,
    network_id = Column(Integer, ForeignKey("network.id"))              # INTEGER NULL,
    device_id = Column(Integer, ForeignKey("device.id"))                # INTEGER NULL,
    is_mgmt = Column(Boolean)                                           # BOOLEAN NOT NULL DEFAULT FALSE,
    description = Column(String(255))                                   # VARCHAR(255) NULL,
    created = Column(DateTime, default=datetime.now(), nullable=False)  # TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated = Column(DateTime)                                          # TIMESTAMP NULL,
    UniqueConstraint("ip_address", "device_id")

    interfaces = relationship("L3Interface", back_populates="ip_address")
    network = relationship("Network", back_populates="ip_address")
    device = relationship("Device", back_populates="ip_address")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def __repr__(self):
        return f"{self.__class__}"

    def __str__(self):
        return f"IPAddres(ip_address={self.ip_address})"


class Network(ipam_base):
    __tablename__ = "network"
    id = Column(Integer, primary_key=True, nullable=False)              # SERIAL PRIMARY KEY,
    network = Column(CIDR, nullable=False)                              # CIDR NOT NULL,
    net_addr = Column(INET)                                             # INET NULL,
    net_mask = Column(INET)                                             # INET NULL,
    mask_length = Column(Integer)                                       # INTEGER NULL,
    wildcard = Column(INET)                                             # INET NULL,
    parent_network_id = Column(Integer, ForeignKey('network.id'))       # INTEGER NULL,
    vlan_id = Column(Integer, ForeignKey('vlan.id'))                    # INTEGER NULL,
    description = Column(String(255))                                   # VARCHAR(255) NULL,
    created = Column(DateTime, default=datetime.now(), nullable=False)  # TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated = Column(DateTime)                                          # TIMESTAMP NULL

    ip_address = relationship("IPAddres", back_populates="network")
    parent_network = relationship("Network", backref="subnets", remote_side=[id])
    vlan = relationship("VLAN", back_populates="network")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def __repr__(self):
        return f"{self.__class__}"

    def __str__(self):
        return f"Network(network={self.network})"


class VLAN(ipam_base):
    __tablename__ = "vlan"
    id = Column(Integer, primary_key=True, nullable=False)              # SERIAL PRIMARY KEY,
    vlan_id = Column(Integer, nullable=False)                           # INTEGER NOT NULL,
    name = Column(String(255))                                          # VARCHAR NULL,
    description = Column(String(255))                                   # VARCHAR NULL,
    created = Column(DateTime, default=datetime.now(), nullable=False)  # TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated = Column(DateTime)                                          # TIMESTAMP NULL

    network = relationship("Network", back_populates="vlan")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def __repr__(self):
        return f"{self.__class__}"

    def __str__(self):
        return f"VLAN({self.vlan_id=})"


class VRF(ipam_base):
    __tablename__ = "vrf"
    id = Column(Integer, primary_key=True, nullable=False)              # SERIAL PRIMARY KEY,
    name = Column(String(255), nullable=False)                          # VARCHAR NOT NULL,
    rd = Column(String(255))                                            # VARCHAR NULL,
    created = Column(DateTime, default=datetime.now(), nullable=False)  # TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated = Column(DateTime)                                          # TIMESTAMP NULL

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def __repr__(self):
        return f"{self.__class__}"

    def __str__(self):
        return f"VRF({self.name=})"


class L3Interface(ipam_base):
    __tablename__ = "l3_interface"
    id = Column(Integer, primary_key=True, nullable=False)              # SERIAL PRIMARY KEY,
    name = Column(String(255), nullable=False)                          # VARCHAR NOT NULL,
    ip_address_id = Column(Integer, ForeignKey('ip_address.id'))        # INTEGER NULL,
    vrf_id = Column(Integer, ForeignKey('vrf.id'))                      # INTEGER NULL,
    device_id = Column(Integer, ForeignKey('device.id'), nullable=False)  # INTEGER NOT NULL,
    created = Column(DateTime, default=datetime.now(), nullable=False)  # TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated = Column(DateTime)                                          # TIMESTAMP NULL

    ip_address = relationship("IPAddres", back_populates="interfaces")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def __repr__(self):
        return f"{self.__class__}"

    def __str__(self):
        return f"L3Interface(name='{self.name}', device_id={self.device_id})"


class NetworkType(ipam_base):
    __tablename__ = "network_type"
    id = Column(Integer, primary_key=True, nullable=False)              # SERIAL PRIMARY KEY ,
    network_type = Column(String(255))                                  # VARCHAR NOT NULL,
    description = Column(String(255))                                   # VARCHAR NULL,
    created = Column(DateTime, default=datetime.now(), nullable=False)  # TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated = Column(DateTime)                                          # TIMESTAMP NULL

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def __repr__(self):
        return f"{self.__class__}"

    def __str__(self):
        return f"NetworkType(network_type='{self.network_type}')"


class Device(ipam_base):
    __tablename__ = "device"
    id = Column(Integer, primary_key=True, nullable=False)              # SERIAL PRIMARY KEY,
    name = Column(String(255))                                          # VARCHAR NOT NULL,
    cred_id = Column(Integer, ForeignKey('cred.id'))                    # INTEGER NOT NULL,
    description = Column(String(255))                                   # VARCHAR NULL,
    created = Column(DateTime, default=datetime.now(), nullable=False)  # TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated = Column(DateTime)                                          # TIMESTAMP NULL

    ip_address = relationship("IPAddres", back_populates="device")
    cred = relationship("Cred", back_populates="devices")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def __repr__(self):
        return f"{self.__class__}"

    def __str__(self):
        return f"Device(name='{self.name}', mgmt_ip='{self.mgmt_ip}')"


class Cred(ipam_base):
    __tablename__ = "cred"
    id = Column(Integer, primary_key=True, nullable=False)              # SERIAL PRIMARY KEY,
    username = Column(String(255), nullable=False)                      # VARCHAR(255) NOT NULL,
    password = Column(String(255), nullable=False)                      # VARCHAR(255) NOT NULL,
    enable_pass = Column(String(255))                                   # VARCHAR(255) NULL,
    netmiko_device = Column(String(255))                                # VARCHAR(255) NULL,
    scrapli_driver = Column(String(255))                                # VARCHAR(255) NULL,
    scrapli_transport = Column(String(255))                             # VARCHAR(255) NULL,
    created = Column(DateTime, default=datetime.now(), nullable=False)  # TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated = Column(DateTime)                                          # TIMESTAMP NULL

    devices = relationship("Device", back_populates="cred")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def __repr__(self):
        return f"{self.__class__}"

    def __str__(self):
        return f"Cred(*args, **kwargs)"


if __name__ == "__main__":
    nets = ipam_db_session.query(Network).all()
    print([net for net in nets])
    for net in nets:
        print(net)
