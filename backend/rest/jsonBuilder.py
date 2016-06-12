import simplejson as json
import pyodbc
import ast

try:

    cnx = pyodbc.connect('Driver={SQL Server};Server=SAMSUNG-PC\SQLEXPRESS;Database=astro;Trusted_Connection=yes;uid=SAMSUNG-PC\SAMSUNG;pwd=')
    #cnx = pyodbc.connect('Driver={SQL Server};Server=GPLPL0041\SQLEXPRESS;Database=Astro;Trusted_Connection=yes;uid=GFT\pwji;pwd=')
    cursor = cnx.cursor()


    get_Ids = ("select distinct(Id) from bi.observationsSorted order by id desc")
    cursor.execute(get_Ids)
    getIds = cursor.fetchall()
    getIds = [g[0] for g in getIds]
    print getIds

    controller = ''
    count = ''

    for counter in getIds:
       id=str(counter)
       get_objectName = ("select distinct(StarName) from bi.observationsSorted where id="+id)
       get_StartDate = ("select top 1 StartDate from bi.observationsSorted where id="+id)
       get_EndDate = ("select top 1 EndDate from bi.observationsSorted where id="+id)
       get_UPhotometryFlag = ("select count(1) from bi.uPhotometrySorted where id="+id)
       get_UPhotometryFlux = ("select uPhotometry from bi.uPhotometrySorted where id="+id)
       get_UPhotometryTime = ("select uPhotometryTime from bi.uPhotometrySorted where id="+id)
       get_VPhotometryFlag = ("select count(1) from bi.vPhotometrySorted where id="+id)
       get_VPhotometryFlux = ("select vPhotometry from bi.vPhotometrySorted where id="+id)
       get_VPhotometryTime = ("select vPhotometryTime from bi.vPhotometrySorted where id="+id)
       get_BPhotometryFlag = ("select count(1) from bi.bPhotometrySorted where id="+id)
       get_BPhotometryFlux = ("select bPhotometry from bi.bPhotometrySorted where id="+id)
       get_BPhotometryTime = ("select bPhotometryTime from bi.bPhotometrySorted where id="+id)

       cursor.execute(get_objectName)
       objectName = cursor.fetchone()
       objectName = objectName[0]

       cursor.execute(get_StartDate)
       StartDate = cursor.fetchone()
       StartDate = str(StartDate[0])

       cursor.execute(get_EndDate)
       EndDate = cursor.fetchone()
       EndDate = str(EndDate[0])

       cursor.execute(get_UPhotometryFlag)
       UPhotometry = cursor.fetchone()
       UPhotometry = str(UPhotometry[0])
       if UPhotometry != 'null':
           UPhotometry = 'YES'
       else:
           UPhotometry = 'NO'

       cursor.execute(get_UPhotometryFlux)
       UPhotometryFlux = cursor.fetchall()
       UPhotometryFlux = [u[0] for u in UPhotometryFlux]
       UPhotometryFlux = ans = ' '.join(UPhotometryFlux).replace(' ', '\n')

       cursor.execute(get_UPhotometryTime)
       UPhotometryTime = cursor.fetchall()
       UPhotometryTime = [u[0] for u in UPhotometryTime]
       UPhotometryTime = ans = ' '.join(UPhotometryTime).replace(' ', '\n')

       cursor.execute(get_VPhotometryFlag)
       VPhotometry = cursor.fetchone()
       VPhotometry = str(VPhotometry[0])
       if VPhotometry != 'null':
          VPhotometry = 'YES'
       else:
          VPhotometry = 'NO'

       cursor.execute(get_VPhotometryFlux)
       VPhotometryFlux = cursor.fetchall()
       VPhotometryFlux = [v[0] for v in VPhotometryFlux]
       VPhotometryFlux = ans = ' '.join(VPhotometryFlux).replace(' ', '\n')

       cursor.execute(get_VPhotometryTime)
       VPhotometryTime = cursor.fetchall()
       VPhotometryTime = [v[0] for v in VPhotometryTime]
       VPhotometryTime = ans = ' '.join(VPhotometryTime).replace(' ', '\n')

       cursor.execute(get_BPhotometryFlag)
       BPhotometry = cursor.fetchone()
       BPhotometry = str(BPhotometry[0])
       if BPhotometry != 'null':
          BPhotometry = 'YES'
       else:
          BPhotometry = 'NO'

       cursor.execute(get_BPhotometryFlux)
       BPhotometryFlux = cursor.fetchall()
       BPhotometryFlux = [b[0] for b in BPhotometryFlux]
       BPhotometryFlux = ans = ' '.join(BPhotometryFlux).replace(' ', '\n')

       cursor.execute(get_BPhotometryTime)
       BPhotometryTime = cursor.fetchall()
       BPhotometryTime = [b[0] for b in BPhotometryTime]
       BPhotometryTime = ans = ' '.join(BPhotometryTime).replace(' ', '\n')

       object = {'id': id, 'name': objectName, 'startDate': StartDate,
                  'endDate': EndDate,
                  'uPhotometry': UPhotometry, 'uPhotometryFlux': UPhotometryFlux, 'uPhotometryTime': UPhotometryTime,
                  'vPhotometry': VPhotometry, 'vPhotometryFlux': VPhotometryFlux, 'vPhotometryTime': VPhotometryTime,
                  'bPhotometry': BPhotometry, 'bPhotometryFlux': BPhotometryFlux, 'bPhotometryTime': BPhotometryTime}

       controller = str(object) + ',' + controller

    controller = controller[:-1]
    controller = ast.literal_eval(controller)

    try:
       print 'Processing ...'
       #print json.dumps(controller, skipkeys=True)
    except (TypeError, ValueError) as err:
       print 'ERROR:', err
    controller = json.dumps(controller, skipkeys=True)

    json_string = json.dumps(controller, skipkeys=True, sort_keys=True, indent=2)
    json_string = json.loads(controller)


#------------------------------------------------get last Processed data------------------------------------------------

    get_LastLoadObservationId = ("select distinct(lg.ObservationId) from log.log lg join bi.observationsSorted os on lg.ObservationId=os.Id where lg.LastLoad=1")
    get_LastLoadStarName = ("select distinct(os.StarName) from log.log lg join bi.observationsSorted os on lg.ObservationId=os.Id where lg.LastLoad=1")
    get_LastLoadStartDate = ("select distinct(cast(os.StartDate as varchar)) from log.log lg join bi.observationsSorted os on lg.ObservationId=os.Id where lg.LastLoad=1")
    get_LastLoadEndDate = ("select distinct(cast(os.EndDate as varchar)) from log.log lg join bi.observationsSorted os on lg.ObservationId=os.Id where lg.LastLoad=1")

    cursor.execute(get_LastLoadObservationId)
    LastLoadObservationId = cursor.fetchone()
    LastLoadObservationId = LastLoadObservationId[0]

    cursor.execute(get_LastLoadStarName)
    LastLoadStarName = cursor.fetchone()
    LastLoadStarName = LastLoadStarName[0]

    cursor.execute(get_LastLoadStartDate)
    LastLoadStartDate = cursor.fetchone()
    LastLoadStartDate = LastLoadStartDate[0]

    cursor.execute(get_LastLoadEndDate)
    LastLoadEndDate = cursor.fetchone()
    LastLoadEndDate = LastLoadEndDate[0]


    lastLoad = [{'observationId': LastLoadObservationId, 'starName': LastLoadStarName, 'startDate': LastLoadStartDate, 'endDate': LastLoadEndDate}]

    cursor.close()

    print lastLoad
except:
        print 'errors'
else:
    cnx.close()

def json_data():
    json_data.jsonData = json_string

def json_load():
    json_load.jsonLastLoad = lastLoad