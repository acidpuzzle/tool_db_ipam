/*
 *
 *
 *
 */

---------- TABLES ON DATABASE ipam_db ----------------------------------------------------

-- IP ADDRESS TABLE
CREATE TABLE "ip_address"(
    "id" SERIAL PRIMARY KEY,
    "ip_address" INET NOT NULL,
    "network_id" INTEGER NULL,
    "device_id" INTEGER NULL,
    "is_mgmt" BOOLEAN NOT NULL DEFAULT FALSE,
    "description" VARCHAR(255) NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL
);

-- IP NETWORK TABLE
CREATE TABLE "network"(
    "id" SERIAL PRIMARY KEY,
    "network" CIDR NOT NULL,
    "net_addr" INET NULL,
    "net_mask" INET NULL,
    "mask_length" INTEGER NULL,
    "wildcard" INET NULL,
    "parent_network_id" INTEGER NULL,
    "vlan_id" INTEGER NULL,
    "description" VARCHAR(255) NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL
);

-- VLAN TABLE
CREATE TABLE "vlan"(
    "id" SERIAL PRIMARY KEY,
    "vlan_id" INTEGER NOT NULL,
    "name" VARCHAR(255) NULL,
    "description" VARCHAR(255) NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL
);

-- VRF TABLE
CREATE TABLE "vrf"(
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "rd" VARCHAR(255) NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL
);
ALTER TABLE vrf
    ADD CONSTRAINT check_correct_rd CHECK (vrf.rd ~ $$^\d+:\d+$$);
INSERT INTO "vrf" (name) VALUES ('default');

-- LAYER 3 INTERFACE TABLE
CREATE TABLE "l3_interface"(
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "ip_address_id" INTEGER NULL,
    "vrf_id" INTEGER NULL,
    "device_id" INTEGER NOT NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL
);

-- NETWORKS TYPE TABLE
CREATE TABLE "network_type"(
    "id" SERIAL PRIMARY KEY ,
    "network_type" VARCHAR(255) NOT NULL,
    "description" VARCHAR(255) NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL
);

-- MANY TO MANY NETWORK TO TYPE
CREATE TABLE "relate_network_network_type"(
    "network_id" INTEGER NOT NULL,
    "network_type_id" INTEGER NOT NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL,
    PRIMARY KEY ("network_id", "network_type_id")
);

-- DEVICE TABLE
CREATE TABLE "device"(
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "description" VARCHAR(255) NULL,
    "cred_id" INTEGER DEFAULT 1,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL
);

-- MANY TO MANY VRF TO DEVICE
CREATE TABLE "cred"(
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR(255) NOT NULL,
    "password" VARCHAR(255) NOT NULL,
    "enable_pass" VARCHAR(255) NULL,
    "netmiko_device" VARCHAR(255) NULL,
    "scrapli_driver" VARCHAR(255) NULL,
    "scrapli_transport" VARCHAR(255) NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL
);

-- MANY TO MANY VRF TO DEVICE
CREATE TABLE "relate_vrf_to_device"(
    "vrf_id" INTEGER NOT NULL,
    "device_id" INTEGER NOT NULL,
    "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated" TIMESTAMP NULL,
    PRIMARY KEY ("vrf_id", "device_id")
);

-----------------------------------------------------------------------------------------------------

ALTER TABLE "ip_address"
    ADD CONSTRAINT "ip_address_network_id_foreign"
        FOREIGN KEY("network_id")
            REFERENCES "network"("id");

ALTER TABLE "ip_address"
    ADD CONSTRAINT "ip_address_device_id_foreign"
        FOREIGN KEY("device_id")
            REFERENCES "device"("id");

ALTER TABLE "ip_address"
    ADD CONSTRAINT "ip_address_device_id_unique"
        UNIQUE("ip_address", "device_id");

-----------------------------------------------------------------------------------------------------

ALTER TABLE "network"
    ADD CONSTRAINT "network_network_unique"
        UNIQUE("network");

ALTER TABLE "network"
    ADD CONSTRAINT "network_vlan_id_foreign"
        FOREIGN KEY("vlan_id")
            REFERENCES "vlan"("id");

ALTER TABLE "network"
    ADD CONSTRAINT "network_self_foreign"
        FOREIGN KEY("parent_network_id")
            REFERENCES "network"("id");

-----------------------------------------------------------------------------------------------------

ALTER TABLE "l3_interface"
    ADD CONSTRAINT "l3_interface_vrf_id_foreign"
        FOREIGN KEY("vrf_id")
            REFERENCES "vrf"("id");

ALTER TABLE "l3_interface"
    ADD CONSTRAINT "l3_interface_name_vrf_id_device_id_unique"
        UNIQUE("name", "vrf_id", "device_id");

-----------------------------------------------------------------------------------------------------

ALTER TABLE "relate_network_network_type"
    ADD CONSTRAINT "relate_network_network_type_network_type_id_foreign"
        FOREIGN KEY("network_type_id")
            REFERENCES "network_type"("id") ON DELETE CASCADE;

ALTER TABLE "relate_network_network_type"
    ADD CONSTRAINT "relate_network_network_type_network_id_foreign"
        FOREIGN KEY("network_id")
            REFERENCES "network"("id") ON DELETE CASCADE;

ALTER TABLE "relate_network_network_type"
    ADD CONSTRAINT "relate_network_network_type_network_id_network_type_id_unique"
        UNIQUE("network_id", "network_type_id");

-----------------------------------------------------------------------------------------------------

ALTER TABLE "device"
    ADD CONSTRAINT "device_unique"
        UNIQUE("name");

ALTER TABLE "device"
    ADD CONSTRAINT "device_cred_id_foreign"
        FOREIGN KEY("cred_id")
            REFERENCES "cred"("id");

-----------------------------------------------------------------------------------------------------

ALTER TABLE "cred"
    ADD CONSTRAINT "username_password_unique"
        UNIQUE ("username", "password");

-----------------------------------------------------------------------------------------------------

ALTER TABLE "relate_vrf_to_device"
    ADD CONSTRAINT "relate_vrf_to_device_vrf_id_foreign"
        FOREIGN KEY("vrf_id")
            REFERENCES "vrf"("id") ON DELETE CASCADE;
ALTER TABLE "relate_vrf_to_device"
    ADD CONSTRAINT "relate_vrf_to_device_device_id_foreign"
        FOREIGN KEY("device_id")
            REFERENCES "device"("id") ON DELETE RESTRICT;

---------- FUNCTION GENERATE TIMESTAMP ON UPDATE ----------------------------------------------------
create function trigger_set_timestamp() returns trigger
    language plpgsql
as
$$
BEGIN

  NEW.updated = NOW();

  RETURN NEW;

END;

$$;
alter function trigger_set_timestamp() owner to ipam_admin;

create trigger set_timestamp
    before update
    of id, ip_address, device_id, network_id, description
    on ip_address
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of id, network, parent_network_id, vlan_id, description
    on network
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of id, vlan_id, name, description
    on vlan
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of id, name, rd
    on vrf
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of id, name, ip_address_id, vrf_id
    on l3_interface
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of network_id, network_type_id
    on relate_network_network_type
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of vrf_id, device_id
    on relate_vrf_to_device
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of id, network_type, description
    on network_type
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of id, name, description, cred_id
    on device
    for each row
execute procedure trigger_set_timestamp();

create trigger set_timestamp
    before update
    of id, username, password, enable_pass, netmiko_device, scrapli_driver, scrapli_transport
    on cred
    for each row
execute procedure trigger_set_timestamp();
-----------------------------------------------------------------------------------------------------

------- NORMALIZE IP, DROP MASK ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION normalize_ip() RETURNS TRIGGER AS $normalize_ip$
  BEGIN
      NEW.ip_address = host(NEW.ip_address);
  RETURN NEW;
  END;
$normalize_ip$ LANGUAGE plpgsql;

ALTER FUNCTION normalize_ip() OWNER TO ipam_admin;

CREATE TRIGGER normalize_ip BEFORE INSERT OR UPDATE ON ip_address
    FOR EACH ROW EXECUTE PROCEDURE normalize_ip();

------- FUNCTION GENERATE "net_addr", "net_mask", "mask_length", "wildcard" -------------------------
CREATE OR REPLACE FUNCTION set_network_params() RETURNS TRIGGER AS $set_network_params$
  BEGIN
      NEW.net_addr = host(NEW.network);
      NEW.net_mask = netmask(NEW.network);
      NEW.mask_length = masklen(NEW.network);
      NEW.wildcard = hostmask(NEW.network);
  RETURN NEW;
  END;
$set_network_params$ LANGUAGE plpgsql;

ALTER FUNCTION set_network_params() OWNER TO ipam_admin;

CREATE TRIGGER set_network_params BEFORE INSERT OR UPDATE ON network
    FOR EACH ROW EXECUTE PROCEDURE set_network_params();
-----------------------------------------------------------------------------------------------------


------- CHECKING WHETHER AN ADDRESS BELONGS TO A NETWORK --------------------------------------------
CREATE FUNCTION check_network_correct() returns trigger as $check_network_correct$
    DECLARE
        target_network CIDR;
    BEGIN
        SELECT network
        INTO target_network
        FROM network
        WHERE (id = NEW.network_id);

        IF NOT NEW.ip_address << target_network AND NEW.network_id NOTNULL THEN
            RAISE EXCEPTION 'IP address % not in network %', NEW.ip_address, target_network;
        END IF;
        RETURN NEW;
    END;
$check_network_correct$ LANGUAGE plpgsql;

ALTER FUNCTION check_network_correct() OWNER TO ipam_admin;

CREATE TRIGGER check_network_correct BEFORE INSERT OR UPDATE ON ip_address
    FOR EACH ROW EXECUTE PROCEDURE check_network_correct();
-----------------------------------------------------------------------------------------------------


------- CHECKING WHETHER NETWORK BELONGS TO A PARENT NETWORK ----------------------------------------
CREATE FUNCTION check_parent_network_correct() returns trigger as $check_parent_network_correct$
    DECLARE
        target_parent_network CIDR;
    BEGIN
        SELECT network
        INTO target_parent_network
        FROM network
        WHERE (id = NEW.parent_network_id);

        IF NOT NEW.network << target_parent_network AND NEW.parent_network_id NOTNULL THEN
            RAISE EXCEPTION 'Network % not in network %', NEW.network, target_parent_network;
        END IF;
        RETURN NEW;
    END;
$check_parent_network_correct$ LANGUAGE plpgsql;

ALTER FUNCTION check_parent_network_correct() OWNER TO ipam_admin;

CREATE TRIGGER check_parent_network_correct BEFORE INSERT OR UPDATE ON network
    FOR EACH ROW EXECUTE PROCEDURE check_parent_network_correct();
-----------------------------------------------------------------------------------------------------

ALTER DATABASE ipam_db owner to ipam_admin;

INSERT INTO "vlan" ("vlan_id", "name", "description")
VALUES (1, 'default', 'Default untagget vlan 1');

INSERT INTO "network_type" ("network_type", "description")
VALUES ('public', 'Public network');

INSERT INTO "network_type" ("network_type", "description")
VALUES ('private', 'Private network');

INSERT INTO "network_type" ("network_type", "description")
VALUES ('p2p transit', 'Point-to-Point transit network');

INSERT INTO "network_type" ("network_type", "description")
VALUES ('p2mp transit', 'Point-to-Multipoint transit network');

INSERT INTO "network_type" ("network_type", "description")
VALUES ('stub access', 'Network for endpoint devices');

INSERT INTO "network_type" ("network_type", "description")
VALUES ('mgmt', 'Device managment network');

INSERT INTO "network_type" ("network_type", "description")
VALUES ('voice', 'IP phone network');

INSERT INTO "network" ("network", description)
VALUES ('10.9.116.0/24', 'oko mgmt network');

INSERT INTO "network" ("network", description)
VALUES ('10.9.112.0/26', 'oko mgmt network');

ALTER TABLE "l3_interface"
ALTER COLUMN vrf_id SET DEFAULT 1;

