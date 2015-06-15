<?xml version="1.0" encoding="UTF-8"?>

<!-- COPYRIGHT © 2015
    MICHIGAN STATE UNIVERSITY BOARD OF TRUSTEES
    ALL RIGHTS RESERVED
    
    PERMISSION IS GRANTED TO USE, COPY, CREATE DERIVATIVE WORKS AND REDISTRIBUTE
    THIS SOFTWARE AND SUCH DERIVATIVE WORKS FOR ANY PURPOSE, SO LONG AS THE NAME
    OF MICHIGAN STATE UNIVERSITY IS NOT USED IN ANY ADVERTISING OR PUBLICITY
    PERTAINING TO THE USE OR DISTRIBUTION OF THIS SOFTWARE WITHOUT SPECIFIC,
    WRITTEN PRIOR AUTHORIZATION.  IF THE ABOVE COPYRIGHT NOTICE OR ANY OTHER
    IDENTIFICATION OF MICHIGAN STATE UNIVERSITY IS INCLUDED IN ANY COPY OF ANY
    PORTION OF THIS SOFTWARE, THEN THE DISCLAIMER BELOW MUST ALSO BE INCLUDED.
    
    THIS SOFTWARE IS PROVIDED AS IS, WITHOUT REPRESENTATION FROM MICHIGAN STATE
    UNIVERSITY AS TO ITS FITNESS FOR ANY PURPOSE, AND WITHOUT WARRANTY BY
    MICHIGAN STATE UNIVERSITY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING
    WITHOUT LIMITATION THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE. THE MICHIGAN STATE UNIVERSITY BOARD OF TRUSTEES SHALL
    NOT BE LIABLE FOR ANY DAMAGES, INCLUDING SPECIAL, INDIRECT, INCIDENTAL, OR
    CONSEQUENTIAL DAMAGES, WITH RESPECT TO ANY CLAIM ARISING OUT OF OR IN
    CONNECTION WITH THE USE OF THE SOFTWARE, EVEN IF IT HAS BEEN OR IS HEREAFTER
    ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
    
    Code written by Lucas Mak
    2015
    (c) Michigan State University Board of Trustees
    Licensed under GNU General Public License (GPL) Version 2. -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output encoding="UTF-8" indent="yes" method="xml"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:key name="countryCode" match="pair" use="@country"/>
    <xsl:key name="channelCode" match="pair" use="@channel"/>
    <xsl:key name="dimensionsCode" match="pair" use="@dimensions"/>
    <xsl:key name="speedCode" match="pair" use="@speed"/>
    <xsl:key name="genreLookup" match="pair" use="lower-case(@discogs_term)"/>
    
    <xsl:variable name="base-uri" select="tokenize(base-uri(),'/')"/>    
        
    <xsl:template match="root">
        <xsl:result-document href="{substring-before($base-uri[last()],'.xml')}_MARC.xml">
            <!-- Genres variable -->
            <xsl:variable name="genre">
                <xsl:value-of select="string-join(genres/item,'/')"/>
            </xsl:variable>
            <xsl:variable name="style">
                <xsl:value-of select="string-join(styles/item,'/')"/>
            </xsl:variable>
            <!-- Genre mapping -->
            <xsl:variable name="genre_mapped">
                <xsl:for-each select="$genre|$style">
                    <xsl:for-each select="key('genreLookup',lower-case(.),document('genreDiscogsConversionTable.xml'))">
                        <xsl:call-template name="genre_mapping"/>   
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable>
            <!-- Channel variable -->
            <xsl:variable name="channel">
                <xsl:for-each select="formats/item/descriptions/item">
                    <xsl:for-each select="key('channelCode',.,document('carrierCode.xml'))">
                        <pair>
                            <xsl:attribute name="channel">
                                <xsl:value-of select="@channel"/>
                            </xsl:attribute>
                            <xsl:attribute name="code">
                                <xsl:value-of select="@code"/>                        
                            </xsl:attribute>
                        </pair>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable>
            <!-- Dimensions variable -->
            <xsl:variable name="dimensions">
                <xsl:for-each select="formats/item/descriptions/item">
                    <xsl:for-each select="key('dimensionsCode',.,document('carrierCode.xml'))">
                        <pair>
                            <xsl:attribute name="dimensions">
                                <xsl:value-of select="@dimensions"/>
                            </xsl:attribute>
                            <xsl:attribute name="code">
                                <xsl:value-of select="@code"/>                        
                            </xsl:attribute>
                        </pair>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable>
            <!-- Speed variable -->
            <xsl:variable name="speed">
                <xsl:for-each select="formats/item/descriptions/item">
                    <xsl:for-each select="key('speedCode',.,document('carrierCode.xml'))">
                        <pair>
                            <xsl:attribute name="speedCode">
                                <xsl:value-of select="@speedCode"/>
                            </xsl:attribute>
                            <xsl:attribute name="code">
                                <xsl:value-of select="@code"/>                        
                            </xsl:attribute>
                        </pair>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:element name="marc:record">
                <!-- MARC Leader -->
                <xsl:element name="marc:leader">
                    <xsl:text>     n</xsl:text>
                    <!-- Music or Non-music -->
                    <xsl:choose>
                        <xsl:when test="matches($genre,'non-music','i')">
                            <xsl:text>i</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>j</xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>m a22     5a 4500</xsl:text>
                </xsl:element>
                
                <!-- MARC 003 -->
                <marc:controlfield tag="003">OCoLC</marc:controlfield>
                
                <!-- MARC 005 -->
                <marc:controlfield tag="005">
                    <xsl:value-of select="substring(replace(string(current-dateTime()),'[:T-]','','i'),1,16)"/>
                </marc:controlfield>
                
                <!-- MARC 007 -->
                <marc:controlfield tag="007">
                    <xsl:text>sd </xsl:text>
                    <xsl:variable name="formats" select="lower-case(string-join(formats/item/name,'/'))"/>
                    <xsl:choose>
                        <!-- Shellac -->
                        <xsl:when test="$formats='shellac'">
                            <!-- Speed -->
                            <xsl:choose>
                                <xsl:when test="string-length($speed//@code)=0">
                                    <xsl:text>d</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$speed//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Channel -->
                            <xsl:choose>
                                <xsl:when test="string-length($channel//@code)=0">
                                    <xsl:text>m</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$channel//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Groove -->
                            <xsl:text>s</xsl:text>
                            <!-- Dimensions -->
                            <xsl:choose>
                                <xsl:when test="string-length($dimensions//@code)=0">
                                    <xsl:text>d</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$dimensions//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:text>nnmsuua</xsl:text>
                        </xsl:when>
                        <!-- Vinyl -->
                        <xsl:when test="$formats='vinyl'">
                            <!-- Speed -->
                            <xsl:choose>
                                <xsl:when test="string-length($speed//@code)=0">
                                    <xsl:text>b</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$speed//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Channel -->
                            <xsl:choose>
                                <xsl:when test="string-length($channel//@code)=0">
                                    <xsl:text>|</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$channel//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Groove -->
                            <xsl:text>m</xsl:text>
                            <!-- Dimensions -->
                            <xsl:choose>
                                <xsl:when test="string-length($dimensions//@code)=0">
                                    <xsl:text>e</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$dimensions//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:text>nnmpuda</xsl:text>
                        </xsl:when>
                        <!-- CD/SACD/CDR/DVD/Blu-ray -->
                        <xsl:when test="$formats='cd' or $formats='sacd' or $formats='cdr' or $formats='dvd' or $formats='blu-ray'">
                            <!-- Speed -->
                            <xsl:choose>
                                <xsl:when test="string-length($speed//@code)=0">
                                    <xsl:text>f</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$speed//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Channel -->
                            <xsl:choose>
                                <xsl:when test="string-length($channel//@code)=0">
                                    <xsl:text>|</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$channel//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Groove -->
                            <xsl:text>n</xsl:text>
                            <!-- Dimensions -->
                            <xsl:choose>
                                <xsl:when test="string-length($dimensions//@code)=0">
                                    <xsl:text>g</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$dimensions//@code"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:text>nnmmn||</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </marc:controlfield>
                
                <!-- MARC 008 -->
                <marc:controlfield tag="008">
                    <!-- 00-05 Record entry time -->
                    <xsl:value-of select="substring(replace(string(current-dateTime()),'[:T-]','','i'),3,6)"/>
                    <!-- 06 Date type-->
                    <xsl:choose>
                        <xsl:when test="string-length(released_formatted)!=0">
                            <xsl:text>t</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>n</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- 07-14 Dates 1 & 2-->
                    <xsl:choose>
                        <xsl:when test="year='0'">
                            <xsl:text>uuuuuuuu</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="string-length(year)=1">
                                    <xsl:value-of select="concat('000',year,'000',year)"/>
                                </xsl:when>
                                <xsl:when test="string-length(year)=2">
                                    <xsl:value-of select="concat('00',year,'00',year)"/>
                                </xsl:when>
                                <xsl:when test="string-length(year)=3">
                                    <xsl:value-of select="concat('0',year,'0',year)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat(substring(year,1,4),substring(year,1,4))"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- 15-17 Country code-->
                    <xsl:choose>
                        <xsl:when test="country">
                            <xsl:for-each select="key('countryCode',country,document('discogsCountryCodeConversionTable.xml'))">
                                <xsl:value-of select="@countryCode"/>        
                            </xsl:for-each>            
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>xx </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- 18-19 Form of composition, 20 Format of music, 21 Music parts -->
                    <xsl:choose>
                        <xsl:when test="matches($genre,'non-music')">
                            <xsl:text>nnnn</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>||||</xsl:otherwise>
                    </xsl:choose>
                    <!-- 22 Target audience -->
                    <xsl:text> </xsl:text>
                    <!-- 23 Form of item -->
                    <xsl:text> </xsl:text>
                    <!-- 24-29 Accompanying matter -->
                    <xsl:text>||||||</xsl:text>
                    <!-- 30-31 Literary text for sound recordings -->
                    <xsl:choose>
                        <xsl:when test="matches($genre,'non-music')">
                            <xsl:text>||</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>  </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- 32 Undefined -->
                    <xsl:text> </xsl:text>
                    <!-- 33 Transposition and arrangement -->
                    <xsl:text>|</xsl:text>
                    <!-- 34 Undefined -->
                    <xsl:text> </xsl:text>
                    <!-- 35-37 Language -->
                    <xsl:text>|||</xsl:text>
                    <!-- 38 Modified record -->
                    <xsl:text> </xsl:text>
                    <!-- 39 Cataloging source -->
                    <xsl:text>d</xsl:text>
                </marc:controlfield>
                
                <!-- MARC 024, 028, & 037 -->
                <xsl:for-each select="identifiers">
                    <!-- Barcode -->
                    <xsl:for-each select="item[type='Barcode']">
                        <marc:datafield tag="024" ind1="1" ind2=" ">
                            <marc:subfield code="a">
                                <xsl:value-of select="replace(value,' ','')"/>
                            </marc:subfield>
                        </marc:datafield>
                    </xsl:for-each>
                    <!-- Matrix number -->
                    <xsl:for-each select="item[type='Matrix / Runout']">
                        <marc:datafield tag="028" ind1="1" ind2="0">
                            <marc:subfield code="a">
                                <xsl:value-of select="value"/>
                            </marc:subfield>
                            <marc:subfield code="b">
                                <!-- Take out Discogs disambiguating number when exists -->
                                <xsl:variable name="marc028b">
                                    <xsl:for-each-group select="ancestor::root/labels/item" group-by="name">
                                        <xsl:value-of select="replace(current-grouping-key(),'\s*\(\d+\)$','')"/>
                                        <xsl:text>/</xsl:text>
                                    </xsl:for-each-group>    
                                </xsl:variable>
                                <xsl:value-of select="replace($marc028b,'/$','')"/>
                            </marc:subfield>
                            <xsl:for-each select="description">
                                <marc:subfield code="q">
                                    <xsl:value-of select="."/>
                                </marc:subfield>
                            </xsl:for-each>
                        </marc:datafield>
                    </xsl:for-each>
                    <!-- Mastering SID Code/Mould SID Code/Other -->
                    <xsl:for-each select="item[type='Mastering SID Code' or type='Mould SID Code' or type='Other']">
                        <marc:datafield tag="024" ind1="8" ind2="0">
                            <marc:subfield code="a">
                                <xsl:value-of select="value"/>
                            </marc:subfield>
                            <xsl:for-each select="description">
                                <marc:subfield code="q">
                                    <xsl:value-of select="lower-case(.)"/>
                                </marc:subfield>
                            </xsl:for-each>
                        </marc:datafield>
                    </xsl:for-each>
                </xsl:for-each>
                <!-- Catalog number -->
                <xsl:for-each select="labels//catno">
                    <marc:datafield tag="028" ind1="0" ind2="0">
                        <marc:subfield code="a">
                            <xsl:value-of select="."/>
                        </marc:subfield>
                        <marc:subfield code="b">
                            <!-- Take out Discogs disambiguating number when exists -->
                            <xsl:variable name="tokenizedName" select="tokenize(parent::item/name,'\s+')"/>
                            <xsl:choose>
                                <xsl:when test="matches($tokenizedName[last()],'([0-9]+)')">
                                    <xsl:for-each select="$tokenizedName[position()!=last()]">
                                        <xsl:copy-of select="."/>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="normalize-space(parent::item/name)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </marc:subfield>
                    </marc:datafield>
                    <!-- ASIN -->
                    <xsl:for-each select="item[type='ASIN']">
                        <marc:datafield tag="037" ind1=" " ind2=" ">
                            <marc:subfield code="a">
                                <xsl:value-of select="value"/>
                            </marc:subfield>
                            <marc:subfield code="b">
                                <xsl:text>Amazon</xsl:text>
                            </marc:subfield>
                        </marc:datafield>
                    </xsl:for-each>
                </xsl:for-each>
    
                <!-- MARC 040 -->
                <marc:datafield tag="040" ind1=" " ind2=" ">
                    <marc:subfield code="a">EEM</marc:subfield>
                    <marc:subfield code="b">eng</marc:subfield>
                    <marc:subfield code="c">EEM</marc:subfield>
                </marc:datafield>
                
                <!-- MARC 049 -->
                <marc:datafield tag="049" ind1=" " ind2=" ">
                    <marc:subfield code="a">EEMJ</marc:subfield>
                </marc:datafield>
    
                <!-- MARC 245 -->
                <xsl:element name="marc:datafield">
                    <xsl:for-each select="title">
                        <xsl:attribute name="tag">245</xsl:attribute>
                        <xsl:attribute name="ind1">
                            <xsl:text>0</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:call-template name="skipCharacter">
                                <xsl:with-param name="title" select="."/>
                            </xsl:call-template>
                        </xsl:attribute>
                        <xsl:element name="marc:subfield">
                            <xsl:attribute name="code">a</xsl:attribute>
                            <xsl:choose>
                                <xsl:when test="parent::root/artists">
                                    <xsl:value-of select="concat(text(),' /')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat(text(),'.')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                    </xsl:for-each>
                    <xsl:for-each select="artists">
                        <xsl:call-template name="statementOfResponsibility">
                            <xsl:with-param name="subfieldCode">c</xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:element>
                
                <!-- MARC 264 Publication-->
                <xsl:element name="marc:datafield">
                    <xsl:attribute name="tag">264</xsl:attribute>
                    <xsl:attribute name="ind1"> </xsl:attribute>
                    <xsl:attribute name="ind2">1</xsl:attribute>
                    <!-- Place of publication -->
                    <xsl:element name="marc:subfield">
                        <xsl:attribute name="code">a</xsl:attribute>
                        <xsl:choose>
                            <xsl:when test="country">
                                <xsl:for-each select="country[string-length()=0]">
                                    <xsl:text>[Place of publication not identified] :</xsl:text>
                                </xsl:for-each>
                                <xsl:for-each select="country[string-length()!=0]">
                                    <xsl:value-of select="concat(normalize-space(.),' :')"/>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>[Place of publication not identified] :</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:element>
                    <!-- Publisher -->
                    <xsl:for-each select="labels[string-length()!=0]">
                        <xsl:for-each-group select="item" group-by="name">
                            <xsl:element name="marc:subfield">
                                <xsl:attribute name="code">b</xsl:attribute>
                                <xsl:choose>
                                    <xsl:when test="string-length(normalize-space(name))=0">
                                        <xsl:text>[publisher not identified]</xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- Take out Discogs disambiguating number when exists -->
                                        <xsl:variable name="tokenizedName" select="tokenize(name,'\s+')"/>
                                        <xsl:choose>
                                            <xsl:when test="matches($tokenizedName[last()],'([0-9]+)')">
                                                <xsl:for-each select="$tokenizedName[position()!=last()]">
                                                    <xsl:copy-of select="."/>
                                                </xsl:for-each>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="normalize-space(name)"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:choose>
                                    <xsl:when test="position()!=last()">
                                        <xsl:text> :</xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>,</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:element>
                        </xsl:for-each-group>
                    </xsl:for-each>
                    <!-- If <labels> does not exist -->
                    <xsl:for-each select="labels[string-length()=0]">
                        <marc:subfield code="b">[publisher not identified],</marc:subfield>
                    </xsl:for-each>
                        
                    <!-- Date of publication -->
                    <xsl:element name="marc:subfield">
                        <xsl:attribute name="code">c</xsl:attribute>
                        <xsl:for-each select="year">
                            <xsl:choose>
                                <!-- If no date available -->
                                <xsl:when test=".='0'">
                                    <xsl:text>[date of publication not identified]</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat(.,'.')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:element>
                </xsl:element>
                
                <!-- MARC 264 Copyrights-->
                <xsl:for-each select="released_formatted">
                    <marc:datafield tag="264" ind1=" " ind2="4">
                        <marc:subfield code="c">
                            <xsl:value-of select="concat('℗',.)"/>
                        </marc:subfield>
                    </marc:datafield>
                </xsl:for-each>
                
                <!-- Physical description -->
                <xsl:for-each select="formats">
                    <!-- MARC 300 -->
                    <xsl:element name="marc:datafield">
                        <xsl:attribute name="tag">300</xsl:attribute>
                        <xsl:attribute name="ind1">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="ind2">
                            <xsl:text> </xsl:text>
                        </xsl:attribute>
                        <xsl:element name="marc:subfield">
                            <xsl:attribute name="code">a</xsl:attribute>
                            <xsl:value-of select="item[matches(name,'vinyl|shellac|cd|blu-ray|dvd','i')]/qty"/>
                            <xsl:choose>
                                <xsl:when test="number(item[matches(name,'vinyl|shellac|cd|blu-ray|dvd','i')]/qty)=1">
                                    <xsl:text> audio disc :</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text> audio discs :</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                        <xsl:element name="marc:subfield">
                            <xsl:attribute name="code">b</xsl:attribute>
                            <xsl:choose>
                                <xsl:when test="item[matches(name,'vinyl|shellac','i')]">
                                    <xsl:text>analog ;</xsl:text>
                                </xsl:when>
                                <xsl:when test="item[matches(name,'cd|blu-ray|dvd','i')]">
                                    <xsl:text>digital ;</xsl:text>
                                </xsl:when> 
                            </xsl:choose>
                        </xsl:element>
                        <xsl:element name="marc:subfield">
                            <xsl:attribute name="code">c</xsl:attribute>
                            <xsl:choose>
                                <xsl:when test="string-length($dimensions//@dimensions)=0">
                                    <xsl:if test="lower-case(item/name)='vinyl'">
                                        <xsl:text>12 in.</xsl:text>
                                    </xsl:if>
                                    <xsl:if test="lower-case(item/name)='shellac'">
                                        <xsl:text>10 in.</xsl:text>
                                    </xsl:if>  
                                    <xsl:if test="lower-case(item/name)='cd' or lower-case(item/name)='sacd' or lower-case(item/name)='cdr' or lower-case(item/name)='dvd' or lower-case(item/name)='blu-ray'">
                                        <xsl:text>4 3/4 in.</xsl:text>
                                    </xsl:if> 
                                </xsl:when>
                                <xsl:when test="$dimensions//@dimensions='LP'">
                                    <xsl:text>12 in.</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat(replace(substring-before($dimensions//@dimensions,'&quot;'),'½',' 1/2'), 'in.')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                    </xsl:element>
                    
                    <!-- MARC 336 -->
                    <marc:datafield tag="336" ind1=" " ind2=" ">
                        <xsl:choose>
                            <xsl:when test="matches($genre,'non-music','i')">
                                <marc:subfield code="a">spoken word</marc:subfield>
                                <marc:subfield code="b">spw</marc:subfield>
                            </xsl:when>
                            <xsl:otherwise>
                                <marc:subfield code="a">performed music</marc:subfield>
                                <marc:subfield code="b">prm</marc:subfield>
                            </xsl:otherwise>
                        </xsl:choose>
                        <marc:subfield code="2">rdacontent</marc:subfield>
                    </marc:datafield>
                    
                    <!-- MARC 337 -->
                    <marc:datafield tag="337" ind1=" " ind2=" ">
                        <marc:subfield code="a">audio</marc:subfield>
                        <marc:subfield code="b">s</marc:subfield>
                        <marc:subfield code="2">rdamedia</marc:subfield>
                    </marc:datafield>
                    
                    <!-- MARC 338 -->
                    <marc:datafield tag="338" ind1=" " ind2=" ">
                        <marc:subfield code="a">audio disc</marc:subfield>
                        <marc:subfield code="b">sd</marc:subfield>
                        <marc:subfield code="2">rdacarrier</marc:subfield>
                    </marc:datafield>
                    
                    <!-- MARC 340 -->
                    <marc:datafield tag="340" ind1=" " ind2=" ">
                        <xsl:choose>
                            <xsl:when test="item[matches(name,'cd|blu-ray|dvd','i')]">
                                <marc:subfield code="a">plastic</marc:subfield>
                                <marc:subfield code="a">metal</marc:subfield>
                            </xsl:when>
                            <xsl:when test="item[matches(name,'vinyl|shellac','i')]">
                                <marc:subfield code="a">
                                    <xsl:value-of select="lower-case(item[matches(name,'vinyl|shellac','i')]/name)"/>
                                </marc:subfield>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:choose>
                            <xsl:when test="string-length($dimensions//@dimensions)=0">
                                <xsl:if test="lower-case(item/name)='vinyl'">
                                    <marc:subfield code="b">
                                        <xsl:text>12 in.</xsl:text>
                                    </marc:subfield>
                                </xsl:if>
                                <xsl:if test="lower-case(item/name)='shellac'">
                                    <marc:subfield code="b">
                                        <xsl:text>10 in.</xsl:text>
                                    </marc:subfield>
                                </xsl:if>    
                                <xsl:if test="lower-case(item/name)='cd' or lower-case(item/name)='sacd' or lower-case(item/name)='cdr' or lower-case(item/name)='dvd' or lower-case(item/name)='blu-ray'">
                                    <marc:subfield code="b">
                                        <xsl:text>4 3/4 in.</xsl:text>
                                    </marc:subfield>
                                </xsl:if> 
                            </xsl:when>
                            <xsl:when test="$dimensions//@dimensions='LP'">
                                <marc:subfield code="b">
                                    <xsl:text>12 in.</xsl:text>
                                </marc:subfield>
                            </xsl:when>
                            <xsl:otherwise>
                                <marc:subfield code="b">
                                    <xsl:value-of select="concat(replace(substring-before($dimensions//@dimensions,'&quot;'),'½',' 1/2'), 'in.')"/>
                                </marc:subfield>
                            </xsl:otherwise>
                        </xsl:choose>
                        <marc:subfield code="2">rda</marc:subfield>
                    </marc:datafield>
                   
                    <!-- MARC 344 -->
                    <marc:datafield tag="344" ind1=" " ind2=" ">
                        <xsl:choose>
                            <xsl:when test="item[matches(name,'vinyl|shellac','i')]">
                                <marc:subfield code="a">analog</marc:subfield>
                            </xsl:when>
                            <xsl:otherwise>
                                <marc:subfield code="a">digital</marc:subfield>
                            </xsl:otherwise>
                        </xsl:choose>
                        <!-- Speed -->
                        <xsl:choose>
                            <xsl:when test="string-length($speed//@speed)!=0">
                                <marc:subfield code="c">
                                    <xsl:value-of select="lower-case(replace(replace($speed//@speed,'⅓',' 1/3'),'⅔',' 2/3'))"/>
                                </marc:subfield>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="item[matches(name,'vinyl','i')]">
                                        <marc:subfield code="c">
                                            <xsl:text>33 1/3 rpm</xsl:text>
                                        </marc:subfield>
                                    </xsl:when>
                                    <xsl:when test="item[matches(name,'shellac','i')]">
                                        <marc:subfield code="c">
                                            <xsl:text>78 rpm</xsl:text>
                                        </marc:subfield>
                                    </xsl:when>
                                    <xsl:when test="item[matches(name,'cd|blu-ray|dvd','i')]">
                                        <marc:subfield code="c">
                                            <xsl:text>1.4 m/s</xsl:text>
                                        </marc:subfield>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                        <!-- Groove -->
                        <xsl:choose>
                            <xsl:when test="item[matches(name,'vinyl','i')]">
                                <marc:subfield code="d">microgroove</marc:subfield>        
                            </xsl:when>
                            <xsl:when test="item[matches(name,'shellac','i')]">
                                <marc:subfield code="d">coarse groove</marc:subfield>        
                            </xsl:when>
                        </xsl:choose>
                        <!-- Channel -->
                        <xsl:choose>
                            <xsl:when test="string-length($channel//@channel)!=0">
                                <xsl:choose>
                                    <xsl:when test="$channel='Ambisonic'">
                                        <marc:subfield code="g">surround</marc:subfield>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <marc:subfield code="g">
                                            <xsl:value-of select="lower-case($channel//@channel)"/>
                                        </marc:subfield>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:when test="item[matches(name,'shellac','i')]">
                                <marc:subfield code="g">mono</marc:subfield>   
                            </xsl:when>
                        </xsl:choose>
                        <marc:subfield code="2">rda</marc:subfield>
                    </marc:datafield>
                </xsl:for-each>
                
                <!-- MARC 382 -->
                <xsl:copy-of select="$genre_mapped/marc:datafield[@tag=382]"/>
                
                <!-- MARC 490 -->
                <xsl:for-each select="series/item/name">
                    <marc:datafield tag="490" ind1="0" ind2=" ">
                        <marc:subfield code="a">
                            <xsl:value-of select="."/>
                        </marc:subfield>
                    </marc:datafield>
                </xsl:for-each>
                
                <!-- Source of title note -->
                <marc:datafield tag="500" ind1=" " ind2=" ">
                    <marc:subfield code="a">
                        <xsl:text>Title from Discogs.com.</xsl:text>
                    </marc:subfield>
                </marc:datafield>
                
                <!-- General note -->
                <xsl:for-each select="notes">
                    <marc:datafield tag="500" ind1=" " ind2=" ">
                        <marc:subfield code="a">
                            <xsl:value-of select="normalize-space(.)"/>
                        </marc:subfield>
                    </marc:datafield>
                </xsl:for-each>
                <xsl:for-each select="item[type='Label Code']">
                    <marc:datafield tag="500" ind1=" " ind2=" ">
                        <marc:subfield code="a">
                            <xsl:value-of select="normalize-space(concat('&quot;',value,'&quot;','.'))"/>
                        </marc:subfield>
                    </marc:datafield>
                </xsl:for-each>
                
                <!-- MARC 511 -->
                <xsl:for-each select="extraartists">
                    <xsl:if test="string-length()!=0">
                        <marc:datafield tag="511" ind1="0" ind2=" ">
                            <xsl:call-template name="statementOfResponsibility">
                                <xsl:with-param name="subfieldCode">a</xsl:with-param>
                            </xsl:call-template>
                        </marc:datafield>
                    </xsl:if>
                </xsl:for-each>
    
                <!-- Track info -->
                <xsl:for-each select="tracklist">
                    <!-- MARC 505 -->
                    <xsl:element name="marc:datafield">
                        <xsl:attribute name="tag">505</xsl:attribute>
                        <xsl:attribute name="ind1">0</xsl:attribute>
                        <xsl:attribute name="ind2"> </xsl:attribute>
                        <xsl:element name="marc:subfield">
                            <xsl:attribute name="code">a</xsl:attribute>
                            <xsl:variable name="content">
                                <xsl:for-each select="item">
                                    <!-- Track title -->
                                    <xsl:value-of select="title"/>
                                    <!-- Statement of responsiblity -->
                                    <xsl:if test="extraartists or artists"> / </xsl:if>
                                    <xsl:for-each-group select="artists/item|extraartists/item" group-by="role">
                                        <xsl:value-of select="concat(lower-case(normalize-space(replace(current-grouping-key(),'[\[\]-]',' '))),' ')"/>
                                        <xsl:variable name="name-string">
                                            <xsl:for-each select="current-group()/name">
                                                <xsl:value-of select="replace(.,' (\(|\])\p{N}+(\)|\])','')"/>
                                                <xsl:text>, </xsl:text>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:value-of select="replace($name-string,', $','')"/>
                                        <xsl:if test="position()!=last()">
                                            <xsl:text> ; </xsl:text>
                                        </xsl:if>
                                    </xsl:for-each-group>    
                                    <!-- Duration -->
                                    <xsl:for-each select="duration[string-length()!=0]">
                                        <xsl:value-of select="concat(' (',.,')')"/>
                                    </xsl:for-each>
                                    <!-- Separator -->
                                    <xsl:choose>
                                        <xsl:when test="position()!=last()">
                                            <xsl:text> -- </xsl:text>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:for-each>
                            </xsl:variable>
                            <!-- Check ending punctuation of Content Note -->
                            <xsl:choose>
                                <xsl:when test="ends-with($content,'.') or ends-with($content,')')">
                                    <xsl:value-of select="normalize-space($content)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="normalize-space(concat($content,'.'))"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                    </xsl:element>
                </xsl:for-each>
     
                <!-- MARC 650 & 655 -->
                <xsl:for-each-group select="$genre_mapped/marc:datafield[@tag=650]" group-by=".">
                    <xsl:sequence select="."/>
                </xsl:for-each-group>
                <xsl:for-each-group select="$genre_mapped/marc:datafield[@tag=655]" group-by=".">
                    <xsl:sequence select="."/>
                </xsl:for-each-group>
                
                <!-- MARC 7XX -->
                <xsl:for-each select="artists">
                    <xsl:for-each select="item">
                        <xsl:call-template name="artistName">
                            <xsl:with-param name="tag">70</xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:for-each>
                
                <!-- MARC 856 -->
                <xsl:for-each select="uri">
                    <marc:datafield tag="856" ind1="4" ind2="2">
                        <marc:subfield code="u">
                            <xsl:value-of select="."/>
                        </marc:subfield>
                        <marc:subfield code="z">
                            <xsl:text>Connect to record on Discogs.com -- All users</xsl:text>
                        </marc:subfield>
                    </marc:datafield>
                </xsl:for-each>
            </xsl:element>
        </xsl:result-document>
    </xsl:template>
    
    <!-- Template to determine skip character for title -->
    <xsl:template name="skipCharacter">
        <xsl:param name="title"/>
        <xsl:choose>
            <xsl:when test="starts-with(lower-case($title),'the ') or starts-with(lower-case($title),'les ')">4</xsl:when>
            <xsl:when test="starts-with(lower-case($title),'an ') or starts-with(lower-case($title),'le ')">3</xsl:when>
            <xsl:when test="starts-with(lower-case($title),'a ')">2</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:template>    
    
    <!-- Template to create 245$c -->
    <xsl:template name="statementOfResponsibility">
        <xsl:param name="subfieldCode"/>
        <xsl:variable name="statementOfResponsibility">
            <xsl:for-each-group select="item" group-by="role">
                <!-- Sort group by role -->
                <!--xsl:sort select="current-grouping-key()"/-->
                <xsl:for-each-group select="current-group()" group-by="join">
                    <!-- Sort group by join -->
                    <xsl:sort select="current-grouping-key()" order="descending"/>
                    <!-- Insert role -->
                    <xsl:choose>
                        <xsl:when test="string-length(role)!=0">
                            <xsl:value-of select="concat(lower-case(replace(role,'-',' ')),', ')"/>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:for-each select="current-group()">
                        <!-- Take out Discogs disambiguating number when exists-->
                        <xsl:variable name="name">
                            <xsl:choose>
                                <xsl:when test="string-length(anv)!=0">
                                    <xsl:variable name="tokenizedName" select="tokenize(anv,'\s+')"/>
                                    <xsl:choose>
                                        <xsl:when test="matches($tokenizedName[last()],'([0-9]+)')">
                                            <xsl:for-each select="$tokenizedName[position()!=last()]">
                                                <xsl:copy-of select="."/>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="anv"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:variable name="tokenizedName" select="tokenize(name,'\s+')"/>
                                    <xsl:choose>
                                        <xsl:when test="matches($tokenizedName[last()],'([0-9]+)')">
                                            <xsl:for-each select="$tokenizedName[position()!=last()]">
                                                <xsl:copy-of select="."/>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="name"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <!-- Check for inverted initial article -->
                        <xsl:choose>
                            <xsl:when test="ends-with($name,', The')">
                                <xsl:value-of select="normalize-space(concat('the ',substring-before($name,', The')))"/>
                            </xsl:when>
                            <xsl:when test="ends-with($name,', the')">
                                <xsl:value-of select="normalize-space(concat('the ',substring-before($name,', the')))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$name"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <!-- Insert separator between names -->
                        <xsl:choose>
                            <!-- If <join> is empty -->
                            <xsl:when test="string-length(join)=0">
                                <xsl:choose>
                                    <xsl:when test="position()!=last()">
                                        <xsl:text>, </xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:choose>
                                    <!-- If <join> has a comma -->
                                    <xsl:when test="join=','">
                                        <xsl:text>, </xsl:text>
                                    </xsl:when>
                                    <!-- If <join> has value other than a comma -->
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat(' ',lower-case(join),' ')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each-group>
                <!-- Insert separator between roles -->
                <xsl:choose>
                    <xsl:when test="position()!=last()">
                        <xsl:text>; </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>.</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:variable>
        <!-- Generate MARC 245$c or 511$a -->
        <xsl:element name="marc:subfield">
            <xsl:attribute name="code">
                <xsl:value-of select="$subfieldCode"/>
            </xsl:attribute>
            <xsl:variable name="sor">
                <xsl:choose>
                    <xsl:when test="ends-with(normalize-space($statementOfResponsibility),'.') or ends-with(normalize-space($statementOfResponsibility),')') or ends-with(normalize-space($statementOfResponsibility),'!')">
                        <xsl:value-of select="normalize-space($statementOfResponsibility)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat(normalize-space($statementOfResponsibility),'.')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- Capitalize first word -->
            <xsl:value-of select="normalize-space(concat(upper-case(substring($sor,1,1)),substring($sor,2)))"/>
        </xsl:element>
    </xsl:template>
    
    <!-- Tempalte mapping Discogs genre/style to LC terms -->
    <xsl:template name="genre_mapping">
        <xsl:for-each select="@lcgft1[string-length()!=0]|@lcgft2[string-length()!=0]">
            <marc:datafield tag="655" ind1=" " ind2="7">
                <marc:subfield code="a">
                    <xsl:value-of select="replace(concat(normalize-space(.),'.'),'\)\.',')')"/>
                </marc:subfield>
                <marc:subfield code="2">lcgft</marc:subfield>
            </marc:datafield>
        </xsl:for-each>
        <xsl:for-each select="@lcsh1[string-length()!=0]|@lcsh2[string-length()!=0]">
            <marc:datafield tag="650" ind1=" " ind2="0">
                <xsl:analyze-string select="." regex=".+\|.+">
                    <xsl:matching-substring>
                        <marc:subfield code="a">
                            <xsl:value-of select="normalize-space(substring-before(.,'|'))"/>
                        </marc:subfield>
                        <marc:subfield code="{substring(replace(substring-after(.,'|'),'^\s',''),1,1)}">
                            <xsl:value-of select="concat(normalize-space(replace(substring-after(.,'|'),'^[a-z]\s','')),'.')"/>
                        </marc:subfield>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <marc:subfield code="a">
                            <xsl:value-of select="replace(concat(normalize-space(.),'.'),'\)\.',')')"/>
                        </marc:subfield>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </marc:datafield>
        </xsl:for-each>
        <xsl:for-each select="@lcmpt[string-length()!=0]">
            <marc:datafield tag="382" ind1=" " ind2=" ">
                <marc:subfield code="a">
                    <xsl:value-of select="normalize-space(.)"/>
                </marc:subfield>
                <marc:subfield code="2">lcmpt</marc:subfield>
            </marc:datafield>
        </xsl:for-each>
        <xsl:for-each select="@discogs_term">
            <marc:datafield tag="655" ind1=" " ind2="4">
                <marc:subfield code="a">
                    <xsl:value-of select="concat(normalize-space(.),'.')"/>
                </marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Template to lookup LCNAF through Discogs profile and Wikipedia -->
    <xsl:template name="artistName">
        <xsl:param name="tag"/>
        <xsl:choose>
            <!-- https://api.discogs.com/artists/194 causes timeout -->
            <xsl:when test="not(resource_url='https://api.discogs.com/artists/194')">
                <xsl:choose>
                    <!-- Test availablity of resource_url text -->
                    <xsl:when test="unparsed-text-available(resource_url)">
                        <xsl:choose>
                            <!-- If resource_url text has a link to Wikipedia -->
                            <xsl:when test="contains(unparsed-text(resource_url),'wikipedia.org/')">
                                <xsl:variable name="wikipediaURL" select="concat(substring(substring-before(unparsed-text(resource_url),'wikipedia.org'),string-length(substring-before(unparsed-text(resource_url),'wikipedia.org'))-9),'wikipedia.org',substring-before(substring-after(unparsed-text(resource_url),'wikipedia.org'),'&quot;]'))"/>
                                <xsl:choose>
                                    <!-- Test availablity of wikipedia text -->
                                    <xsl:when test="unparsed-text-available($wikipediaURL)">
                                        <xsl:choose>
                                            <!-- If Wikipedia text has a link to LCNAF -->
                                            <xsl:when test="contains(unparsed-text($wikipediaURL),'id.loc.gov/authorities/names/')">
                                                <xsl:call-template name="lcnaf">
                                                    <xsl:with-param name="wikipediaURL" select="$wikipediaURL"/>
                                                    <xsl:with-param name="tag" select="$tag"/>
                                                </xsl:call-template>
                                            </xsl:when>
                                            <!-- If Wikipedia text does not have a link to LCNAF -->
                                            <xsl:otherwise>
                                                <xsl:choose>
                                                    <!-- If Wikipedia page is English -->
                                                    <xsl:when test="contains($wikipediaURL,'/en.')">
                                                        <xsl:call-template name="accessPoints">
                                                            <xsl:with-param name="tag" select="$tag"/>
                                                        </xsl:call-template>
                                                    </xsl:when>
                                                    <!-- If Wikipedia page is non-English -->
                                                    <xsl:otherwise>
                                                        <xsl:choose>
                                                            <!-- If non-English Wikipedia page has link to English Wikipedia page -->
                                                            <xsl:when test="contains(unparsed-text($wikipediaURL),'interlanguage-link interwiki-en')">
                                                                <xsl:variable name="wikipediaURL" select="concat('http:',substring-before(substring-after(substring-after(unparsed-text($wikipediaURL),'interlanguage-link interwiki-en'),'href=&quot;'),'&quot;'))"/>
                                                                <xsl:choose>
                                                                    <!-- Test availablity of English wikipedia text -->
                                                                    <xsl:when test="unparsed-text-available($wikipediaURL)">
                                                                        <xsl:choose>
                                                                            <!-- If English Wikipedia page has a link to LCNAF -->
                                                                            <xsl:when test="contains(unparsed-text($wikipediaURL),'http://id.loc.gov/authorities/names/')">
                                                                                <xsl:call-template name="lcnaf">
                                                                                    <xsl:with-param name="wikipediaURL" select="$wikipediaURL"/>
                                                                                    <xsl:with-param name="tag" select="$tag"/>
                                                                                </xsl:call-template>
                                                                            </xsl:when>
                                                                            <!-- If English Wikipedia page does not have link to LCNAF -->
                                                                            <xsl:otherwise>
                                                                                <xsl:call-template name="accessPoints">
                                                                                    <xsl:with-param name="tag" select="$tag"/>
                                                                                </xsl:call-template>
                                                                            </xsl:otherwise>
                                                                        </xsl:choose>
                                                                    </xsl:when>
                                                                    <!-- If English Wikipedia page does not exist -->
                                                                    <xsl:otherwise>
                                                                        <xsl:call-template name="accessPoints">
                                                                            <xsl:with-param name="tag" select="$tag"/>
                                                                        </xsl:call-template>
                                                                    </xsl:otherwise>
                                                                </xsl:choose>
                                                            </xsl:when>
                                                            <!-- If non-English Wikipedia page does not have link to English Wikipedia page -->
                                                            <xsl:otherwise>
                                                                <xsl:call-template name="accessPoints">
                                                                    <xsl:with-param name="tag" select="$tag"/>
                                                                </xsl:call-template>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <!-- If Wikipedia text is not available -->
                                    <xsl:otherwise>
                                        <xsl:call-template name="accessPoints">
                                            <xsl:with-param name="tag" select="$tag"/>
                                        </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <!-- If resource_url text does not have a link to Wikipedia -->
                            <xsl:otherwise>
                                <xsl:call-template name="accessPoints">
                                    <xsl:with-param name="tag" select="$tag"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- If resource_url text is not available-->
                    <xsl:otherwise>
                        <xsl:call-template name="accessPoints">
                            <xsl:with-param name="tag" select="$tag"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- artist is "Various artists" -> no AP -->
        </xsl:choose>
    </xsl:template>
    
    <!-- Template to copy LCNAF AAP -->
    <xsl:template name="lcnaf">
        <xsl:param name="wikipediaURL"/>
        <xsl:param name="tag"/>
        <!-- Access LCNAF -->
        <xsl:for-each select="document(concat('http://id.loc.gov/authorities/names/',substring-before(substring-after(unparsed-text($wikipediaURL),'id.loc.gov/authorities/names/'),'&quot;'),'.marcxml.xml'))//marc:datafield[@tag=100 or @tag=110]">
            <xsl:variable name="tag">
                <xsl:choose>
                    <xsl:when test="@tag=100">
                        <xsl:value-of select="concat(substring($tag,1,1),'00')"/>
                    </xsl:when>
                    <xsl:when test="@tag=110">
                        <xsl:value-of select="concat(substring($tag,1,1),'10')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat(substring($tag,1,1),'11')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <marc:datafield tag="{$tag}" ind1="{@ind1}" ind2="{@ind2}">
                <xsl:copy-of select="marc:subfield[position()!=last()]"/>
                <xsl:for-each select="marc:subfield[last()]">
                    <marc:subfield code="{@code}">
                        <xsl:choose>
                            <xsl:when test="matches(.,'[-$\)$\?$\.$]')">
                                <xsl:value-of select="."/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat(.,'.')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </marc:subfield>
                </xsl:for-each>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Template to create access points -->
    <xsl:template name="accessPoints">
        <xsl:param name="tag"/>
        <xsl:param name="ind1">
            <xsl:text>1</xsl:text>
        </xsl:param>
        <xsl:choose>
            <!-- If name contains comma, treat as inverted form -->
            <xsl:when test="contains(name,',')">
                <xsl:choose>
                    <!-- corporate -->
                    <xsl:when test="matches(name,', the$','i')">
                        <marc:datafield tag="{concat(substring($tag,1,1),'10')}" ind1="2" ind2=" ">
                            <marc:subfield code="a">
                                <xsl:value-of select="normalize-space(concat(replace(name,', the$','','i'),'.'))"/>
                            </marc:subfield>
                        </marc:datafield>
                    </xsl:when>
                    <xsl:when test="matches(.,' and |^The | the | Group| group|^Los |^Les |^La | of | on | under |Orchestra|Ensemble')">
                        <marc:datafield tag="{number(concat(substring($tag,1,1),'10'))}" ind1="2" ind2=" ">
                            <marc:subfield code="a">
                                <xsl:value-of select="concat(normalize-space(replace(.,'^The |^Los |^Les |^La ','','i')),'.')"/>
                            </marc:subfield>
                        </marc:datafield>
                    </xsl:when>
                    <!-- inverted personal -->
                    <xsl:otherwise>
                        <marc:datafield tag="{concat($tag,0)}" ind1="{$ind1}" ind2=" ">
                             <marc:subfield code="a">
                                  <xsl:value-of select="concat(name,'.')"/>
                             </marc:subfield>
                        </marc:datafield>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- If name does not contain space, copy as is -->
            <!-- direct personal -->
            <xsl:when test="not(contains(name,' '))">
                <xsl:element name="marc:datafield">
                    <xsl:attribute name="tag">
                        <xsl:value-of select="concat($tag,'0')"/>
                    </xsl:attribute>
                    <xsl:attribute name="ind1">
                        <xsl:text>0</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="ind2">
                        <xsl:text> </xsl:text>
                    </xsl:attribute>
                    <xsl:element name="marc:subfield">
                        <xsl:attribute name="code">a</xsl:attribute>
                        <xsl:value-of select="concat(name,'.')"/>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            <!-- If name does not contain space nor comma -->
            <!-- personal -->
            <xsl:otherwise>
                <marc:datafield tag="{concat($tag,'0')}" ind1="{$ind1}" ind2=" ">
                     <marc:subfield code="a">
                          <!-- Tokenize name by space(s) -->
                          <xsl:variable name="tokenizedName" select="tokenize(name,'\s+')"/>
                          <xsl:choose>
                              <!-- If name contains Discogs disambiguating number -->
                              <xsl:when test="matches($tokenizedName[last()],'([0-9]+)')">
                                  <xsl:variable name="tokenizedNameNormalized">
                                      <!-- Copy all except the last token -->
                                      <xsl:for-each select="$tokenizedName[position()!=last()]">
                                          <xsl:copy-of select="."/>
                                      </xsl:for-each>
                                  </xsl:variable>
                                  <!-- Re-tokenize the name without Discogs disambiguating number -->
                                  <xsl:variable name="tokenizedName" select="tokenize($tokenizedNameNormalized,'\s+')"/>
                                  <!-- Create AP in inverted form -->
                                  <xsl:call-template name="ap">
                                      <xsl:with-param name="tokenizedName" select="$tokenizedName"/>
                                  </xsl:call-template>    
                              </xsl:when>
                              <!-- If name does not contain Discogs disambiguating number -->
                              <xsl:otherwise>
                                  <!-- Create AP in inverted form -->
                                  <xsl:call-template name="ap">
                                      <xsl:with-param name="tokenizedName" select="$tokenizedName"/>
                                  </xsl:call-template>  
                              </xsl:otherwise>
                          </xsl:choose>
                     </marc:subfield>
                </marc:datafield>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Template to create AP -->
    <xsl:template name="ap">
        <xsl:param name="tokenizedName"/>
        <!-- Select the last element of the name -->
        <xsl:for-each select="$tokenizedName[position()=last()]">
            <xsl:value-of select="concat(.[last()],', ')"/>
        </xsl:for-each>
        <!-- Select element of the name that is not the last or second to last -->
        <xsl:for-each select="$tokenizedName[position()!=last() and position()!=last()-1]">
            <xsl:value-of select="concat(.,' ')"/>
        </xsl:for-each>
        <!-- Select second to the last element of the name -->
        <xsl:for-each select="$tokenizedName[position()=last()-1]">
            <xsl:value-of select="replace(concat(.,'.'),'\.\.$','.')"/>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>