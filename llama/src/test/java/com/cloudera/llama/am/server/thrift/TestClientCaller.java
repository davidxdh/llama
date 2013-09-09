/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.cloudera.llama.am.server.thrift;

import com.cloudera.llama.thrift.LlamaNotificationService;
import junit.framework.Assert;
import org.apache.hadoop.conf.Configuration;
import org.junit.Test;
import org.mockito.Mockito;

import java.util.UUID;

public class TestClientCaller {

  static boolean createClient;

  public static class MyClientCaller extends ClientCaller {

    public MyClientCaller(String clientId, UUID handle,
        String host, int port) {
      super(new Configuration(false), clientId, handle, host, port);
    }

    @Override LlamaNotificationService.Iface createClient() throws Exception {
      createClient = true;
      return Mockito.mock(LlamaNotificationService.Iface.class);
    }
  }

  @Test
  public void testClientCallerOK() throws Exception {
    final String cId = "id";
    final UUID handle = UUID.randomUUID();
    ClientCaller cc = new MyClientCaller(cId, handle, "h", 0);
    Assert.assertEquals(cId, cc.getClientId());

    ClientCaller.Callable<Boolean> callable =
        new ClientCaller.Callable<Boolean>() {
          @Override
          public Boolean call() throws ClientException {
            Assert.assertEquals(cId, getClientId());
            Assert.assertEquals(handle, getHandle());
            Assert.assertNotNull(getClient());
            return Boolean.TRUE;
          }
        };
    createClient = false;
    Assert.assertTrue(cc.execute(callable));
    Assert.assertTrue(createClient);
    createClient = false;
    Assert.assertTrue(cc.execute(callable));
    Assert.assertFalse(createClient);
  }

  @Test(expected = ClientException.class)
  public void testClientCallerFail() throws Exception {
    final String cId = "id";
    final UUID handle = UUID.randomUUID();
    ClientCaller cc = new MyClientCaller(cId, handle, "h", 0);
    Assert.assertEquals(cId, cc.getClientId());

    ClientCaller.Callable<Void> callable =
        new ClientCaller.Callable<Void>() {
          @Override
          public Void call() throws ClientException {
            throw new ClientException(new Exception());
          }
        };
    try {
      createClient = false;
      cc.execute(callable);
    } finally {
      Assert.assertTrue(createClient);
      createClient = false;
      callable = new ClientCaller.Callable<Void>() {
        @Override
        public Void call() throws ClientException {
          return null;
        }
      };
      cc.execute(callable);
      Assert.assertTrue(createClient);
    }
  }

}
