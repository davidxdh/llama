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
package com.cloudera.llama.am.spi;

import com.cloudera.llama.am.Reservation;
import com.cloudera.llama.am.Resource;
import junit.framework.Assert;
import org.junit.Test;

import java.util.Arrays;
import java.util.UUID;

public class TestRMPlacedReservation {
  
  @Test
  public void test() {
    Resource resource = new Resource(UUID.randomUUID(), "l",
        Resource.LocationEnforcement.MUST, 1, 2);
    Reservation reservation = new Reservation(UUID.randomUUID(), "q", 
        Arrays.asList(resource), false);

    RMPlacedReservation pr = new RMPlacedReservation(reservation) {
      @Override
      public UUID getReservationId() {
        return null;
      }

      @Override
      public Status getStatus() {
        return null;
      }
    };

    Assert.assertEquals(1, pr.getResources().size());
    Assert.assertEquals(resource, pr.getResources().get(0));
    Assert.assertEquals(resource, pr.getRMResources().get(0));
  }
}