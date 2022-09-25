
#!/bin/sh

/opt/apache-hive-metastore-3.0.0-bin/bin/schematool -dbType postgres -initSchema
/opt/apache-hive-metastore-3.0.0-bin/bin/start-metastore