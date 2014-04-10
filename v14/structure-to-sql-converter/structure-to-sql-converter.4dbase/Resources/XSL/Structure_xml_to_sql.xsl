<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="text" />
	
	<xsl:param name="Begin_SQL" />	
	<xsl:param name="End_SQL" />		
	<xsl:param name="Wrap" select="0" />		
	<xsl:param name="External" select="0" />	
			
	<xsl:key name="table_by_uuid" match="/base/table" use="./@uuid" />
	<xsl:key name="field_by_uuid" match="/base/table/field" use="./@uuid" />	
	
	<xsl:template match="/">
	
		<xsl:if test="$External">	
			<xsl:text>$pathName:=&quot;&quot;&#xA;</xsl:text>
		</xsl:if>	
	
		<xsl:if test="$Wrap">
		<xsl:value-of select="$Begin_SQL"/>	
			<xsl:text>&#xA;</xsl:text>
		</xsl:if>
			
		<xsl:if test="$External">	
			<xsl:text>&#x9;CREATE DATABASE IF NOT EXISTS DATAFILE :$pathName;&#xA;</xsl:text>
			<xsl:text>&#x9;USE LOCAL DATABASE DATAFILE :$pathName AUTO_CLOSE;&#xA;&#xA;</xsl:text>			
		</xsl:if>
				
		<xsl:apply-templates select="/base/table" />
		<xsl:text>&#xA;</xsl:text>
		<xsl:apply-templates select="/base/index" />

		<xsl:if test="$External">	
			<xsl:text>&#x9;USE DATABASE SQL_INTERNAL;&#xA;</xsl:text>		
		</xsl:if>

		<xsl:if test="$Wrap">
		<xsl:value-of select="$End_SQL"/>	
			<xsl:text>&#xA;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template name="tab">
		<xsl:if test="$Wrap">
			<xsl:text>&#x9;</xsl:text>
		</xsl:if>
	</xsl:template>
		
	<xsl:template name="new-line">
		<xsl:if test="position() != 1">
			<xsl:text>&#xA;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="escape-metacharacters"><!--ESCAPE !&^#% -->
		<xsl:param name="s"/>
		<xsl:param name="e"/>		
		<xsl:choose>
			<xsl:when test="($e = 'true') or
				contains($s, ' ') or 
				contains($s, '!') or 
				contains($s, '&amp;') or 
				contains($s, '^') or 
				contains($s, '#') or 
				contains($s, '%') or
				contains($s, ']') ">
				<xsl:value-of select="'['"/>
				<xsl:call-template name="quote-brackets">
					<xsl:with-param name="s" select="$s"/>
				</xsl:call-template>
				<xsl:value-of select="']'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$s"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="quote-brackets"><!--ESCAPE ] -->
		<xsl:param name="s"/>
		<xsl:choose>
			<xsl:when test="contains($s, ']')">
				<xsl:value-of select="concat(substring-before($s,']'),']]')"/>
				<xsl:call-template name="quote-brackets">
					<xsl:with-param name="s" select="substring-after($s,']')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$s"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>	
	
	<xsl:template match="/base/table">
	
		<xsl:call-template name="new-line"/>

		<xsl:for-each select="./field">
			<!--NEW TABLE -->
			<xsl:if test="position() = 1">
				<xsl:call-template name="tab"/>
				<xsl:text>CREATE TABLE IF NOT EXISTS </xsl:text>
				<!--SCHEMA-->
				<xsl:if test="../@sql_schema_id">
					<xsl:variable name="p" select="number(../@sql_schema_id)"/>
					<xsl:if test="$p &gt; 1">
						<xsl:call-template name="escape-metacharacters">
							<xsl:with-param name="s" select="/base/schema[$p]/@name"/>
							<xsl:with-param name="e" select="/base/schema[$p]/@should-escape"/>
						</xsl:call-template>
						<xsl:text>.</xsl:text>
					</xsl:if>
				</xsl:if>			
				<xsl:call-template name="escape-metacharacters">
					<xsl:with-param name="s" select="../@name"/>
					<xsl:with-param name="e" select="../@should-escape"/>
				</xsl:call-template>
				<xsl:text> (&#xA;</xsl:text>
			</xsl:if>
			<!--NEW FIELD -->
			<xsl:call-template name="tab"/>
			<xsl:text>&#x9;</xsl:text>
			<xsl:call-template name="escape-metacharacters">
					<xsl:with-param name="s" select="@name"/>
					<xsl:with-param name="e" select="@should-escape"/>
				</xsl:call-template>
			<xsl:text> </xsl:text>
			<!--FIELD TYPES-->
			<xsl:choose>
				<xsl:when test="@type = 1">
					<xsl:value-of select="'BOOLEAN'" />
				</xsl:when>
				<xsl:when test="@type = 3">
					<xsl:value-of select="'SMALLINT'" />
				</xsl:when>
				<xsl:when test="@type = 4">
					<xsl:value-of select="'INT'" />
				</xsl:when>
				<xsl:when test="@type = 5">
					<xsl:value-of select="'NUMERIC'" /><!--INT64-->
				</xsl:when>
				<xsl:when test="@type = 6">
					<xsl:value-of select="'REAL'" />
				</xsl:when>
				<xsl:when test="@type = 7">
					<xsl:value-of select="'FLOAT'" />
				</xsl:when>
				<xsl:when test="@type = 8">
					<xsl:value-of select="'TIMESTAMP'" />
				</xsl:when>
				<xsl:when test="@type = 9">
					<xsl:value-of select="'DURATION'" />
				</xsl:when>
				<xsl:when test="@type = 12">
					<xsl:value-of select="'PICTURE'" />
				</xsl:when>
				<xsl:when test="@type = 14">
					<xsl:value-of select="'TEXT'" /><!--OUTSIDE RECORD OR OUTSIDE DATA-->
				</xsl:when>
				<xsl:when test="@type = 15">
					<xsl:value-of select="'INT'" />
				</xsl:when>
				<xsl:when test="@type = 16">
					<xsl:value-of select="'INT'" />
				</xsl:when>
				<xsl:when test="@type = 18">
					<xsl:value-of select="'BLOB'" />
				</xsl:when>
				<xsl:when test="@type = 10">
					<xsl:choose>
						<xsl:when test="@store_as_UUID">
							<xsl:value-of select="'UUID'" />
						</xsl:when>
						<xsl:when test="@limiting_length">
							<xsl:value-of select="concat('VARCHAR (', @limiting_length, ')')" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'TEXT'" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
			</xsl:choose>
			<xsl:if test="@autosequence = 'true'">
				<xsl:value-of select="' AUTO_INCREMENT'" />
			</xsl:if>
			<xsl:if test="@autogenerate = 'true'">
				<xsl:value-of select="' AUTO_GENERATE'" />
			</xsl:if>
			<xsl:if test="@not_null = 'true'">
				<xsl:value-of select="' NOT NULL'" />
				<xsl:if test="@unique = 'true'">
					<xsl:value-of select="' UNIQUE'" />
				</xsl:if>				
			</xsl:if>
				
			<xsl:choose>
				<xsl:when test="position() = last()">
					<!--PRIMARY KEY-->
					<xsl:if test="../primary_key">
						<xsl:text>,&#xA;&#x9;PRIMARY KEY (</xsl:text>
						<xsl:for-each select="../primary_key">
							<xsl:call-template name="escape-metacharacters">
								<xsl:with-param name="s" select="@field_name"/>
								<xsl:with-param name="e" select="key('field_by_uuid', @field_uuid)/@should-escape"/>
							</xsl:call-template>
							<xsl:choose>
							<xsl:when test="position() != last()">
								<xsl:text>,</xsl:text>
							</xsl:when>	
							<xsl:otherwise>
								<xsl:text>)</xsl:text>	
							</xsl:otherwise>
							</xsl:choose>	
						</xsl:for-each>	
					</xsl:if>
					<!--REPLICATE-->	
					<xsl:if test="../@keep_record_sync_info = 'true'">
					<xsl:text>,&#xA;&#x9;ENABLE REPLICATE</xsl:text>
					</xsl:if>
					<xsl:text>&#xA;</xsl:text>
					<xsl:call-template name="tab"/>
					<xsl:text>);&#xA;</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>,&#xA;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		
	</xsl:template>
	
	<xsl:template match="/base/index">
	
		<xsl:call-template name="new-line"/>
		
		<xsl:for-each select="./field_ref">
			<!--NEW INDEX -->
			<xsl:if test="position() = 1">
				<xsl:call-template name="tab"/>
				<xsl:text>CREATE </xsl:text>
				<xsl:if test="../@unique_keys = 'true'">
					<xsl:text>UNIQUE </xsl:text>
				</xsl:if>
				<xsl:text>INDEX </xsl:text>
				<xsl:choose>
					<xsl:when test="../@name">
						<xsl:call-template name="escape-metacharacters">
							<xsl:with-param name="s" select="../@name"/>
							<xsl:with-param name="e" select="../@should-escape"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!--should not happen-->
						<xsl:value-of select="concat('[', generate-id(), ']')" />
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text> ON </xsl:text>
				<xsl:call-template name="escape-metacharacters">
					<xsl:with-param name="s" select="key('table_by_uuid', ./table_ref/@uuid)/@name"/>
					<xsl:with-param name="e" select="key('table_by_uuid', ./table_ref/@uuid)/@should-escape"/>
				</xsl:call-template>
				<xsl:text> (&#xA;</xsl:text>
			</xsl:if>
			<xsl:call-template name="tab"/>
			<xsl:text>&#x9;</xsl:text>
			<xsl:call-template name="escape-metacharacters">
				<xsl:with-param name="s" select="@name"/>
				<xsl:with-param name="e" select="key('field_by_uuid', @uuid)/@should-escape"/>
			</xsl:call-template>
			<xsl:choose>
				<xsl:when test="position() = last()">
					<xsl:text>&#xA;</xsl:text>
					<xsl:call-template name="tab"/>
					<xsl:text>);&#xA;</xsl:text>
				</xsl:when>	
				<xsl:otherwise>
					<xsl:text>,&#xA;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>	
		</xsl:for-each>

	</xsl:template>		
				
</xsl:stylesheet>